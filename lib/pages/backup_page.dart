import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:list/controllers/backup_controller.dart';
import 'package:list/services/hive_backup_service.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final BackupController controller = Get.find<BackupController>();
  late final TextEditingController _rclonePathController;
  late final TextEditingController _rcloneConfigController;
  late final TextEditingController _remoteNameController;
  late final TextEditingController _driveRootController;
  late final TextEditingController _autoIntervalController;
  late final TextEditingController _scheduledTimesController;

  @override
  void initState() {
    super.initState();
    final config = controller.config;
    _rclonePathController = TextEditingController(
      text: config.rcloneExecutablePath,
    );
    _rcloneConfigController = TextEditingController(
      text: config.rcloneConfigPath,
    );
    _remoteNameController = TextEditingController(text: config.remoteName);
    _driveRootController = TextEditingController(text: config.driveRootFolder);
    _autoIntervalController = TextEditingController(
      text: config.autoIntervalMinutes.toString(),
    );
    _scheduledTimesController = TextEditingController(
      text: config.scheduledTimes.join(', '),
    );
  }

  @override
  void dispose() {
    _rclonePathController.dispose();
    _rcloneConfigController.dispose();
    _remoteNameController.dispose();
    _driveRootController.dispose();
    _autoIntervalController.dispose();
    _scheduledTimesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width > 760
        ? 760.0
        : double.infinity;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: const Color.fromARGB(255, 210, 28, 34),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [_statusCard(), const SizedBox(height: 16)],
          ),
        ),
      ),
    );
  }

  Widget _statusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    controller.isConnected.value
                        ? Icons.cloud_done
                        : Icons.cloud_queue,
                    color: controller.isConnected.value
                        ? Colors.green
                        : Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.isConnected.value
                          ? 'Google Drive: Connected'
                          : 'Google Drive: Not tested',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _infoRow(
                'User',
                controller.displayName.value.isEmpty
                    ? 'Not set'
                    : controller.displayName.value,
              ),
              _infoRow(
                'Backup ID',
                controller.backupId.value.isEmpty
                    ? 'Not set'
                    : controller.backupId.value,
              ),
              _infoRow(
                'Last Auto Backup',
                controller.lastAutoBackup.value.isEmpty
                    ? 'Never'
                    : controller.lastAutoBackup.value,
              ),
              _infoRow(
                'Last Manual Backup',
                controller.lastManualBackup.value.isEmpty
                    ? 'Never'
                    : controller.lastManualBackup.value,
              ),
              const Divider(height: 24),
              Text(controller.statusMessage.value),
              if (controller.isBusy.value) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: controller.isBusy.value
                        ? null
                        : () async {
                            await controller.backupNow();
                          },
                    icon: const Icon(Icons.backup),
                    label: const Text('Backup Now'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.isBusy.value
                        ? null
                        : () async {
                            await controller.testConnection();
                          },
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Test Connection'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _settingsCard() {
  //   return Card(
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             'rclone Settings',
  //             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 16),
  //           _field(_rclonePathController, 'rclone executable path', 'rclone'),
  //           _field(
  //             _rcloneConfigController,
  //             'rclone config path',
  //             'Leave blank for default',
  //           ),
  //           _field(_remoteNameController, 'Remote name', 'gdrive'),
  //           _field(
  //             _driveRootController,
  //             'Google Drive root folder',
  //             'LoanLedgerBackups',
  //           ),
  //           _field(
  //             _autoIntervalController,
  //             'Automatic interval minutes',
  //             '30',
  //             keyboardType: TextInputType.number,
  //           ),
  //           _field(
  //             _scheduledTimesController,
  //             'Scheduled backup times',
  //             '08:00, 16:00, 23:00',
  //           ),
  //           const SizedBox(height: 8),
  //           Align(
  //             alignment: Alignment.centerRight,
  //             child: ElevatedButton.icon(
  //               onPressed: _saveSettings,
  //               icon: const Icon(Icons.save),
  //               label: const Text('Save Settings'),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _field(
  //   TextEditingController textController,
  //   String label,
  //   String hint, {
  //   TextInputType? keyboardType,
  // }) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 12),
  //     child: TextField(
  //       controller: textController,
  //       keyboardType: keyboardType,
  //       decoration: InputDecoration(
  //         labelText: label,
  //         hintText: hint,
  //         border: const OutlineInputBorder(),
  //       ),
  //     ),
  //   );
  // }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final interval = int.tryParse(_autoIntervalController.text.trim()) ?? 30;
    final times = _scheduledTimesController.text
        .split(',')
        .map((time) => time.trim())
        .where((time) => RegExp(r'^\d{2}:\d{2}$').hasMatch(time))
        .toList();

    await controller.saveConfig(
      BackupConfig(
        rcloneExecutablePath: _rclonePathController.text.trim().isEmpty
            ? BackupConfig.defaults.rcloneExecutablePath
            : _rclonePathController.text.trim(),
        rcloneConfigPath: _rcloneConfigController.text.trim(),
        remoteName: _remoteNameController.text.trim().isEmpty
            ? BackupConfig.defaults.remoteName
            : _remoteNameController.text.trim(),
        driveRootFolder: _driveRootController.text.trim().isEmpty
            ? BackupConfig.defaults.driveRootFolder
            : _driveRootController.text.trim(),
        autoIntervalMinutes: interval.clamp(1, 1440),
        scheduledTimes: times.isEmpty
            ? BackupConfig.defaults.scheduledTimes
            : times,
      ),
    );
  }
}
