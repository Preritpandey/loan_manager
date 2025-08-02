// main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:list/models/loan.dart';
import 'app.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(LoanAdapter());
  Hive.registerAdapter(PartialRepaymentAdapter());
  await Hive.openBox<Loan>('loans');

  // Request storage permission on app startup
  await Permission.storage.request();

  runApp(const MyApp());
}
