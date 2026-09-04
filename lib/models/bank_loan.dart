import 'package:hive/hive.dart';
import 'package:list/models/loan.dart';

part 'bank_loan.g.dart';

@HiveType(typeId: 10)
class BankLoan extends HiveObject {
  @HiveField(0)
  final String loanId;

  @HiveField(1)
  final DateTime depositDate;

  @HiveField(2)
  final Loan originalLoan;

  @HiveField(3)
  String status; // e.g., 'active', 'settled', 'defaulted'

  BankLoan({
    required this.loanId,
    required this.originalLoan,
    required this.depositDate,
    this.status = 'active',
  });

}
