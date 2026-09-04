// core/app.dart
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NepaliUtils(Language.english);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
