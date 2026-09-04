import 'dart:io';

import 'package:hive/hive.dart';
import 'package:list/models/bank_loan.dart';
import 'package:list/models/deposit.dart';
import 'package:list/models/loan.dart';
import 'package:list/models/loan_event.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum BackupKind { automatic, manual, scheduled }

class BackupConfig {
  const BackupConfig({
    required this.rcloneExecutablePath,
    required this.rcloneConfigPath,
    required this.remoteName,
    required this.driveRootFolder,
    required this.autoIntervalMinutes,
    required this.scheduledTimes,
  });

  final String rcloneExecutablePath;
  final String rcloneConfigPath;
  final String remoteName;
  final String driveRootFolder;
  final int autoIntervalMinutes;
  final List<String> scheduledTimes;

  static const defaults = BackupConfig(
    rcloneExecutablePath: 'rclone',
    rcloneConfigPath: '',
    remoteName: 'gdrive',
    driveRootFolder: 'LoanLedgerBackups',
    autoIntervalMinutes: 30,
    scheduledTimes: ['08:00', '16:00', '23:00'],
  );
}

class BackupResult {
  const BackupResult({
    required this.success,
    required this.message,
    this.snapshotFiles = const [],
  });

  final bool success;
  final String message;
  final List<String> snapshotFiles;
}

class HiveBackupService {
  static const List<String> boxNames = [
    'loans',
    'deposits',
    'events',
    'bankLoans',
  ];
  static const Set<String> _allowedExtensions = {'.hive', '.hivec'};

  Future<BackupResult> testConnection(BackupConfig config) async {
    final ProcessResult executableResult;
    try {
      executableResult = await _runRclone(config, ['version']);
    } on ProcessException catch (e) {
      return BackupResult(
        success: false,
        message: 'rclone not available: ${e.message}',
      );
    }

    if (executableResult.exitCode != 0) {
      return BackupResult(
        success: false,
        message:
            'rclone not available: ${_cleanProcessError(executableResult)}',
      );
    }

    final aboutResult = await _runRclone(config, [
      'about',
      '${config.remoteName}:',
    ]);
    if (aboutResult.exitCode != 0) {
      return BackupResult(
        success: false,
        message:
            'Google Drive connection failed: ${_cleanProcessError(aboutResult)}',
      );
    }

    return const BackupResult(
      success: true,
      message: 'Google Drive connection OK.',
    );
  }

  Future<String> createUniqueBackupId({
    required String displayName,
    required BackupConfig config,
  }) async {
    final normalized = normalizeBackupName(displayName);
    final remoteBase = _remotePath(config, '');
    final result = await _runRclone(config, ['lsf', remoteBase, '--dirs-only']);
    final existing = <String>{};

    if (result.exitCode == 0) {
      final lines = result.stdout.toString().split(RegExp(r'\r?\n'));
      for (final line in lines) {
        final folder = line.trim().replaceAll(RegExp(r'/+$'), '');
        if (folder.isNotEmpty) {
          existing.add(folder);
        }
      }
    }

    for (var index = 1; index < 1000; index++) {
      final candidate = '$normalized${index.toString().padLeft(2, '0')}';
      if (!existing.contains(candidate)) {
        return candidate;
      }
    }

    throw BackupException('Unable to allocate a backup ID for $displayName.');
  }

  Future<BackupResult> runBackup({
    required BackupKind kind,
    required String backupId,
    required BackupConfig config,
  }) async {
    Directory? snapshotDirectory;
    try {
      await _flushOpenBoxes();
      snapshotDirectory = await _createSnapshotDirectory();
      final snapshotFiles = await _copyHiveFiles(snapshotDirectory);

      if (snapshotFiles.isEmpty) {
        return const BackupResult(
          success: false,
          message: 'No Hive database files were found to back up.',
        );
      }

      switch (kind) {
        case BackupKind.automatic:
          return await _uploadAutomaticBackup(
            config: config,
            backupId: backupId,
            snapshotDirectory: snapshotDirectory,
            snapshotFiles: snapshotFiles,
          );
        case BackupKind.manual:
        case BackupKind.scheduled:
          return await _uploadHistoricalBackup(
            config: config,
            backupId: backupId,
            snapshotDirectory: snapshotDirectory,
            snapshotFiles: snapshotFiles,
            kind: kind,
          );
      }
    } on BackupException catch (e) {
      return BackupResult(success: false, message: e.message);
    } on FileSystemException catch (e) {
      return BackupResult(success: false, message: e.message);
    } catch (e) {
      return BackupResult(success: false, message: 'Backup failed: $e');
    } finally {
      if (snapshotDirectory != null && await snapshotDirectory.exists()) {
        try {
          await snapshotDirectory.delete(recursive: true);
        } catch (_) {
          // A stale temp snapshot is safer than risking the live database.
        }
      }
    }
  }

  static String normalizeBackupName(String name) {
    final normalized = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return normalized.isEmpty ? 'user' : normalized;
  }

  Future<void> _flushOpenBoxes() async {
    if (Hive.isBoxOpen('loans')) {
      await Hive.box<Loan>('loans').flush();
    }
    if (Hive.isBoxOpen('deposits')) {
      await Hive.box<DepositModel>('deposits').flush();
    }
    if (Hive.isBoxOpen('events')) {
      await Hive.box<LoanPerformedEvent>('events').flush();
    }
    if (Hive.isBoxOpen('bankLoans')) {
      await Hive.box<BankLoan>('bankLoans').flush();
    }
  }

  Future<Directory> _createSnapshotDirectory() async {
    final tempRoot = await getTemporaryDirectory();
    final directory = Directory(
      p.join(
        tempRoot.path,
        'loan_ledger_backup_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    return directory.create(recursive: true);
  }

  Future<List<String>> _copyHiveFiles(Directory snapshotDirectory) async {
    final files = await _discoverHiveFiles();
    final copiedNames = <String>[];

    for (final file in files) {
      final target = File(p.join(snapshotDirectory.path, p.basename(file.path)));
      await file.copy(target.path);
      copiedNames.add(p.basename(target.path));
    }

    return copiedNames;
  }

  Future<List<File>> _discoverHiveFiles() async {
    final discovered = <String, File>{};

    for (final boxName in boxNames) {
      if (!Hive.isBoxOpen(boxName)) {
        continue;
      }

      final boxPath = _boxPath(boxName);
      if (boxPath == null || boxPath.isEmpty) {
        continue;
      }

      final boxFile = File(boxPath);
      if (await _isBackupDataFile(boxFile, boxName)) {
        discovered[boxFile.path] = boxFile;
      }

      final parent = boxFile.parent;
      if (!await parent.exists()) {
        continue;
      }

      await for (final entity in parent.list(followLinks: false)) {
        if (entity is! File) {
          continue;
        }
        if (await _isBackupDataFile(entity, boxName)) {
          discovered[entity.path] = entity;
        }
      }
    }

    return discovered.values.toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
  }

  String? _boxPath(String boxName) {
    switch (boxName) {
      case 'loans':
        return Hive.box<Loan>('loans').path;
      case 'deposits':
        return Hive.box<DepositModel>('deposits').path;
      case 'events':
        return Hive.box<LoanPerformedEvent>('events').path;
      case 'bankLoans':
        return Hive.box<BankLoan>('bankLoans').path;
    }
    return null;
  }

  Future<bool> _isBackupDataFile(File file, String boxName) async {
    final fileName = p.basename(file.path).toLowerCase();
    if (fileName.endsWith('.lock')) {
      return false;
    }
    if (!fileName.startsWith(boxName.toLowerCase())) {
      return false;
    }
    if (!_allowedExtensions.contains(p.extension(fileName))) {
      return false;
    }
    return file.exists();
  }

  Future<BackupResult> _uploadAutomaticBackup({
    required BackupConfig config,
    required String backupId,
    required Directory snapshotDirectory,
    required List<String> snapshotFiles,
  }) async {
    final timestamp = _timestampForFolder(DateTime.now());
    final stagingPath = '$backupId/AUTO_BACKUP_STAGING_$timestamp';
    final autoPath = '$backupId/AUTO_BACKUP';

    final mkdirResult = await _runRclone(config, [
      'mkdir',
      _remotePath(config, stagingPath),
    ]);
    if (mkdirResult.exitCode != 0) {
      return BackupResult(
        success: false,
        message: 'Could not create staging folder: ${_cleanProcessError(mkdirResult)}',
      );
    }

    final uploadResult = await _runRclone(config, [
      'copy',
      snapshotDirectory.path,
      _remotePath(config, stagingPath),
      '--exclude',
      '*.lock',
    ]);
    if (uploadResult.exitCode != 0) {
      await _bestEffortPurge(config, stagingPath);
      return BackupResult(
        success: false,
        message:
            'Upload failed; previous automatic backup was preserved: '
            '${_cleanProcessError(uploadResult)}',
        snapshotFiles: snapshotFiles,
      );
    }

    final copyResult = await _runRclone(config, [
      'copy',
      _remotePath(config, stagingPath),
      _remotePath(config, autoPath),
    ]);
    if (copyResult.exitCode != 0) {
      await _bestEffortPurge(config, stagingPath);
      return BackupResult(
        success: false,
        message:
            'Uploaded staging copy, but could not replace AUTO_BACKUP: '
            '${_cleanProcessError(copyResult)}',
        snapshotFiles: snapshotFiles,
      );
    }

    await _removeRemoteFilesNotInSnapshot(config, autoPath, snapshotFiles);
    await _bestEffortPurge(config, stagingPath);

    return BackupResult(
      success: true,
      message: 'Automatic backup uploaded.',
      snapshotFiles: snapshotFiles,
    );
  }

  Future<BackupResult> _uploadHistoricalBackup({
    required BackupConfig config,
    required String backupId,
    required Directory snapshotDirectory,
    required List<String> snapshotFiles,
    required BackupKind kind,
  }) async {
    final prefix = kind == BackupKind.scheduled ? 'scheduled' : 'manual';
    final folder =
        '$backupId/MANUAL_BACKUP/${prefix}_${_timestampForFolder(DateTime.now())}';
    final result = await _runRclone(config, [
      'copy',
      snapshotDirectory.path,
      _remotePath(config, folder),
      '--exclude',
      '*.lock',
    ]);

    if (result.exitCode != 0) {
      return BackupResult(
        success: false,
        message:
            'Historical backup upload failed: ${_cleanProcessError(result)}',
        snapshotFiles: snapshotFiles,
      );
    }

    return BackupResult(
      success: true,
      message:
          '${kind == BackupKind.scheduled ? 'Scheduled' : 'Manual'} backup uploaded.',
      snapshotFiles: snapshotFiles,
    );
  }

  Future<void> _removeRemoteFilesNotInSnapshot(
    BackupConfig config,
    String remoteFolder,
    List<String> snapshotFiles,
  ) async {
    final result = await _runRclone(config, [
      'lsf',
      _remotePath(config, remoteFolder),
      '--files-only',
    ]);
    if (result.exitCode != 0) {
      return;
    }

    final expected = snapshotFiles.toSet();
    final remoteFiles = result.stdout.toString().split(RegExp(r'\r?\n'));
    for (final remoteFile in remoteFiles) {
      final fileName = remoteFile.trim();
      if (fileName.isEmpty || expected.contains(fileName)) {
        continue;
      }
      await _runRclone(config, [
        'deletefile',
        _remotePath(config, '$remoteFolder/$fileName'),
      ]);
    }
  }

  Future<void> _bestEffortPurge(BackupConfig config, String remoteFolder) async {
    await _runRclone(config, ['purge', _remotePath(config, remoteFolder)]);
  }

  Future<ProcessResult> _runRclone(BackupConfig config, List<String> args) {
    final fullArgs = <String>[
      if (config.rcloneConfigPath.trim().isNotEmpty) ...[
        '--config',
        config.rcloneConfigPath.trim(),
      ],
      ...args,
    ];
    return Process.run(config.rcloneExecutablePath.trim(), fullArgs);
  }

  String _remotePath(BackupConfig config, String childPath) {
    final root = config.driveRootFolder
        .trim()
        .replaceAll(RegExp(r'^/+|/+$'), '');
    final child = childPath.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    final suffix = child.isEmpty ? root : '$root/$child';
    return '${config.remoteName.trim()}:$suffix';
  }

  String _timestampForFolder(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}_'
        '${two(local.hour)}-${two(local.minute)}';
  }

  String _cleanProcessError(ProcessResult result) {
    final stderr = result.stderr.toString().trim();
    final stdout = result.stdout.toString().trim();
    if (stderr.isNotEmpty) {
      return stderr;
    }
    if (stdout.isNotEmpty) {
      return stdout;
    }
    return 'rclone exited with code ${result.exitCode}.';
  }
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
