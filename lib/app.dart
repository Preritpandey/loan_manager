// core/app.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:list/controllers/otp_verify_controller.dart';
// OFFLINE MODE: Google Drive/rclone backup controller disabled for now.
// import 'package:list/controllers/backup_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/add_loan_page.dart';
// OFFLINE MODE: Backup page route disabled for now.
// import 'package:list/pages/backup_page.dart';
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

    // OFFLINE MODE: Backup-before-exit warning disabled for now.
    // final shouldClose = await _showBackupBeforeCloseDialog();
    // if (!shouldClose) return;

    _isClosing = true;
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  /*
  OFFLINE MODE: Backup-before-exit warning disabled for now.

  Future<bool> _showBackupBeforeCloseDialog() async {
    ...
  }
  */

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
        // OFFLINE MODE: Backup & Restore page disabled for now.
        // GetPage(name: '/backup', page: () => const BackupPage()),
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
        // OFFLINE MODE: Google Drive/rclone backup controller disabled for now.
        // Get.put(BackupController());
      }),
    );
  }
}
