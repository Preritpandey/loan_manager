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
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(LoanAdapter());
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(PartialRepaymentAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(InterestRateChangeAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(BankLoanAdapter());
  await Hive.openBox<Loan>('loans');
  // Register and open deposits boxes
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(CashDepositLotAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(DepositModelAdapter());
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(DepositTransactionAdapter());
  }
  await Hive.openBox<DepositModel>('deposits');
  // Register and open events box
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(LoanPerformedEventAdapter());
  }
  await Hive.openBox<LoanPerformedEvent>('events');

  // Request storage permission on app startup
  await Permission.storage.request();

  runApp(const MyApp());
}
