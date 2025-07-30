// core/app.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/pages/add_loan_page.dart';
import 'package:list/pages/loan_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Loan Manager',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => LoanHomePage()),
        GetPage(name: '/add', page: () => AddLoanPage()),
      ],
    );
  }
}
