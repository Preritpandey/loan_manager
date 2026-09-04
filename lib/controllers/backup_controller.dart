import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:list/services/hive_backup_service.dart';

class BackupController extends GetxController {
  BackupController({HiveBackupService? service})
      : _service = service ?? HiveBackupService();

  static const _displayNameKey = 'backup_display_name';
  static const _backupIdKey = 'backup_id';
  static const _lastAutoBackupKey = 'backup_last_auto';
  static const _lastManualBackupKey = 'backup_last_manual';
  static const _rclonePathKey = 'backup_rclone_path';
  static const _rcloneConfigKey = 'backup_rclone_config_path';
  static const _remoteNameKey = 'backup_remote_name';
  static const _driveRootKey = 'backup_drive_root';
  static const _autoIntervalKey = 'backup_auto_interval_minutes';
  static const _scheduledTimesKey = 'backup_scheduled_times';

  final HiveBackupService _service;

  final RxString displayName = ''.obs;
  final RxString backupId = ''.obs;
  final RxString statusMessage = 'Backup service ready.'.obs;
  final RxString lastAutoBackup = ''.obs;
  final RxString lastManualBackup = ''.obs;
  final RxBool isBusy = false.obs;
  final RxBool isConnected = false.obs;
  final RxBool hasIdentity = false.obs;
  final RxBool isInitialized = false.obs;

  BackupConfig config = BackupConfig.defaults;
  Timer? _autoTimer;
  Timer? _scheduledTimer;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    displayName.value = prefs.getString(_displayNameKey) ?? '';
    backupId.value = prefs.getString(_backupIdKey) ?? '';
    lastAutoBackup.value = prefs.getString(_lastAutoBackupKey) ?? '';
    lastManualBackup.value = prefs.getString(_lastManualBackupKey) ?? '';
    config = BackupConfig(
      rcloneExecutablePath:
          prefs.getString(_rclonePathKey) ??
          BackupConfig.defaults.rcloneExecutablePath,
      rcloneConfigPath:
          prefs.getString(_rcloneConfigKey) ??
          BackupConfig.defaults.rcloneConfigPath,
      remoteName: prefs.getString(_remoteNameKey) ?? BackupConfig.defaults.remoteName,
      driveRootFolder:
          prefs.getString(_driveRootKey) ?? BackupConfig.defaults.driveRootFolder,
      autoIntervalMinutes:
          prefs.getInt(_autoIntervalKey) ?? BackupConfig.defaults.autoIntervalMinutes,
      scheduledTimes:
          prefs.getStringList(_scheduledTimesKey) ?? BackupConfig.defaults.scheduledTimes,
    );
    hasIdentity.value =
        displayName.value.isNotEmpty && backupId.value.isNotEmpty;
    isInitialized.value = true;
    _restartSchedulers();
  }

  Future<void> saveConfig(BackupConfig nextConfig) async {
    final prefs = await SharedPreferences.getInstance();
    config = nextConfig;
    await prefs.setString(_rclonePathKey, nextConfig.rcloneExecutablePath);
    await prefs.setString(_rcloneConfigKey, nextConfig.rcloneConfigPath);
    await prefs.setString(_remoteNameKey, nextConfig.remoteName);
    await prefs.setString(_driveRootKey, nextConfig.driveRootFolder);
    await prefs.setInt(_autoIntervalKey, nextConfig.autoIntervalMinutes);
    await prefs.setStringList(_scheduledTimesKey, nextConfig.scheduledTimes);
    statusMessage.value = 'Backup settings saved.';
    _restartSchedulers();
  }

  Future<void> registerUser(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      statusMessage.value = 'Please enter your name.';
      return;
    }

    isBusy.value = true;
    statusMessage.value = 'Creating Google Drive backup identity...';
    try {
      final id = await _service.createUniqueBackupId(
        displayName: trimmed,
        config: config,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_displayNameKey, trimmed);
      await prefs.setString(_backupIdKey, id);
      displayName.value = trimmed;
      backupId.value = id;
      hasIdentity.value = true;
      statusMessage.value = 'Backup identity created: $id';
      _restartSchedulers();
    } catch (e) {
      final fallback = '${HiveBackupService.normalizeBackupName(trimmed)}01';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_displayNameKey, trimmed);
      await prefs.setString(_backupIdKey, fallback);
      displayName.value = trimmed;
      backupId.value = fallback;
      hasIdentity.value = true;
      statusMessage.value =
          'Saved local backup ID $fallback. Test rclone before relying on Google Drive backups.';
      _restartSchedulers();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> testConnection() async {
    isBusy.value = true;
    statusMessage.value = 'Testing Google Drive connection...';
    try {
      final result = await _service.testConnection(config);
      isConnected.value = result.success;
      statusMessage.value = result.message;
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> backupNow() {
    return _runBackup(BackupKind.manual);
  }

  Future<bool> runAutomaticBackup() {
    return _runBackup(BackupKind.automatic);
  }

  Future<bool> _runBackup(BackupKind kind) async {
    if (!hasIdentity.value) {
      statusMessage.value = 'Set up your backup user first.';
      return false;
    }
    if (isBusy.value) {
      statusMessage.value = 'A backup is already running.';
      return false;
    }

    isBusy.value = true;
    statusMessage.value = 'Preparing backup snapshot...';
    var success = false;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      statusMessage.value = 'Uploading backup to Google Drive...';
      final result = await _service.runBackup(
        kind: kind,
        backupId: backupId.value,
        config: config,
      );

      if (result.success) {
        success = true;
        final now = DateTime.now().toLocal().toString();
        final prefs = await SharedPreferences.getInstance();
        if (kind == BackupKind.automatic) {
          lastAutoBackup.value = now;
          await prefs.setString(_lastAutoBackupKey, now);
        } else {
          lastManualBackup.value = now;
          await prefs.setString(_lastManualBackupKey, now);
        }
        isConnected.value = true;
      }
      statusMessage.value = result.message;
    } finally {
      isBusy.value = false;
    }
    return success;
  }

  void _restartSchedulers() {
    _autoTimer?.cancel();
    _scheduledTimer?.cancel();

    if (!hasIdentity.value || !isInitialized.value) {
      return;
    }

    final interval = Duration(
      minutes: config.autoIntervalMinutes.clamp(1, 1440),
    );
    _autoTimer = Timer.periodic(interval, (_) {
      runAutomaticBackup();
    });
    _scheduledTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _runDueScheduledBackup(),
    );
    _runDueScheduledBackup();
  }

  Future<void> _runDueScheduledBackup() async {
    if (isBusy.value) {
      return;
    }

    final now = DateTime.now();
    final current = _formatClockTime(now);
    if (!config.scheduledTimes.contains(current)) {
      return;
    }

    final key =
        'backup_scheduled_done_${now.year}_${now.month}_${now.day}_$current';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) {
      return;
    }

    final success = await _runBackup(BackupKind.scheduled);
    if (success) {
      await prefs.setBool(key, true);
    }
  }

  String _formatClockTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.hour)}:${two(value.minute)}';
  }

  @override
  void onClose() {
    _autoTimer?.cancel();
    _scheduledTimer?.cancel();
    super.onClose();
  }
}

Future<void> showBackupIdentityDialog(
  BuildContext context,
  BackupController controller,
) async {
  final nameController = TextEditingController();
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Backup Setup'),
        content: TextField(
          controller: nameController,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Your name',
            hintText: 'John Doe',
          ),
          onSubmitted: (_) async {
            await controller.registerUser(nameController.text);
            if (context.mounted && controller.hasIdentity.value) {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isBusy.value
                  ? null
                  : () async {
                      await controller.registerUser(nameController.text);
                      if (context.mounted && controller.hasIdentity.value) {
                        Navigator.of(context).pop();
                      }
                    },
              child: controller.isBusy.value
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ),
        ],
      );
    },
  );
  nameController.dispose();
}
