// core/app.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:list/controllers/otp_verify_controller.dart';
import 'package:list/controllers/backup_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/add_loan_page.dart';
import 'package:list/pages/backup_page.dart';
import 'package:list/pages/loan_page.dart';
import 'package:list/pages/otp_verification_screen.dart';
import 'package:list/pages/splash_screen.dart';
import 'package:list/pages/cash_deposits_page.dart';
import 'package:list/pages/loan_detail_page.dart';
import 'package:nepali_utils/nepali_utils.dart' show NepaliUtils, Language;
import 'package:window_manager/window_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NepaliUtils(Language.english);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    if (!Platform.isWindows || _isClosing) return;

    final isPreventClose = await windowManager.isPreventClose();
    if (!isPreventClose) return;

    final shouldClose = await _showBackupBeforeCloseDialog();
    if (!shouldClose) return;

    _isClosing = true;
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  Future<bool> _showBackupBeforeCloseDialog() async {
    final context = Get.context;
    if (context == null || !context.mounted) return false;

    final backupController = Get.find<BackupController>();
    while (!backupController.isInitialized.value && context.mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var isBackingUp = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> saveAndClose() async {
              setDialogState(() => isBackingUp = true);
              final success = await backupController.backupNow();
              if (!dialogContext.mounted) return;

              setDialogState(() => isBackingUp = false);
              if (success) {
                Navigator.of(dialogContext).pop(true);
              }
            }

            return AlertDialog(
              title: const Text('Save backup before closing?'),
              content: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Save your latest loan data to Google Drive before exiting.',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      backupController.hasIdentity.value
                          ? backupController.statusMessage.value
                          : 'Backup is not set up yet. Open backup settings to connect cloud backup.',
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isBackingUp
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isBackingUp
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Exit Without Backup'),
                ),
                Obx(
                  () => backupController.hasIdentity.value
                      ? FilledButton.icon(
                          onPressed: isBackingUp ? null : saveAndClose,
                          icon: isBackingUp
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(
                            isBackingUp ? 'Saving...' : 'Save to Cloud & Exit',
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: isBackingUp
                              ? null
                              : () {
                                  Navigator.of(dialogContext).pop(false);
                                  Get.toNamed('/backup');
                                },
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Open Backup Setup'),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Loan Manager',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        ...GlobalMaterialLocalizations.delegates,
        ...GlobalCupertinoLocalizations.delegates,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('ne', 'NP'), // Nepali
      ],
      locale: const Locale('en', 'US'),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/home', page: () => LoanHomePage()),
        GetPage(name: '/add', page: () => AddLoanPage()),
        GetPage(name: '/otp', page: () => OtpScreen()),
        GetPage(name: '/splash', page: () => SplashScreen()),
        GetPage(name: '/cash-deposits', page: () => const CashDepositsPage()),
        GetPage(name: '/backup', page: () => const BackupPage()),
        GetPage(
          name: '/loan-details',
          page: () {
            final loan = Get.arguments as Loan;
            return LoanDetailPage(loan: loan);
          },
        ),
      ],
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController());
        Get.put(BackupController());
      }),
    );
  }
}
