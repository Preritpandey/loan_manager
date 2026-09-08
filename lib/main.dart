// main.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:list/models/bank_loan.dart';
import 'package:list/models/loan.dart';
import 'package:list/models/deposit.dart';
import 'package:list/models/loan_event.dart';
import 'app.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
  }

  await Hive.initFlutter();
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(PartialRepaymentAdapter());
  Hive.registerAdapter(InterestRateChangeAdapter());
  Hive.registerAdapter(BankLoanAdapter());
  await Hive.openBox<Loan>('loans');
  // Register and open deposits boxes
  Hive.registerAdapter(DepositModelAdapter());
  Hive.registerAdapter(DepositTransactionAdapter());
  await Hive.openBox<DepositModel>('deposits');
  // Register and open events box
  Hive.registerAdapter(LoanPerformedEventAdapter());
  await Hive.openBox<LoanPerformedEvent>('events');

  // Request storage permission on app startup
  await Permission.storage.request();

  runApp(const MyApp());
}
