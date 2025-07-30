// controllers/loan_controller.dart
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:list/models/loan.dart';

class LoanController extends GetxController {
  final Box<Loan> loanBox = Hive.box<Loan>('loans');
  final loans = <Loan>[].obs;

  @override
  void onInit() {
    loans.value = loanBox.values.toList();
    super.onInit();
  }

  void addLoan(Loan loan) {
    loanBox.add(loan);
    loans.add(loan);
  }

  void updateReceivedAmount(int index, double amount) {
    final loan = loans[index];
    loan.amountReceived = amount;
    loan.save();
    loans[index] = loan;
  }

  List<Loan> search(String query) =>
    loans.where((loan) => loan.name.contains(query) || loan.serialNumber.contains(query)).toList();
}