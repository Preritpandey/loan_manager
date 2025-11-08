import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:list/models/bank_loan.dart';
import 'package:list/models/loan.dart';

class BankLoanController extends GetxController {
  static const String _boxName = 'bankLoans';
  late final Box<BankLoan> _bankLoansBox;

  final RxList<BankLoan> bankLoans = <BankLoan>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _initHive();
      await _loadBankLoans();
      isInitialized.value = true;
    } catch (e) {
      print('Error initializing BankLoanController: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _initHive() async {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(BankLoanAdapter());
    }
    _bankLoansBox = await Hive.openBox<BankLoan>(_boxName);
  }

  Future<void> _loadBankLoans() async {
    try {
      bankLoans.assignAll(_bankLoansBox.values.toList());
    } catch (e) {
      print('Error loading bank loans: $e');
      rethrow;
    }
  }

  Future<bool> addLoanToBank(Loan loan) async {
    try {
      // Check if loan already exists in bank
      if (_bankLoansBox.containsKey(loan.loanId)) {
        return false; // Already exists
      }

      final bankLoan = BankLoan(
        loanId: loan.loanId,
        originalLoan: loan,
        depositDate: DateTime.now(),
      );

      await _bankLoansBox.put(loan.loanId, bankLoan);
      await _loadBankLoans();
      return true;
    } catch (e) {
      print('Error adding loan to bank: $e');
      return false;
    }
  }

  Future<bool> removeLoanFromBank(String loanId) async {
    try {
      await _bankLoansBox.delete(loanId);
      await _loadBankLoans();
      return true;
    } catch (e) {
      print('Error removing loan from bank: $e');
      return false;
    }
  }

  bool isLoanInBank(String loanId) {
    return _bankLoansBox.containsKey(loanId);
  }

  @override
  void onClose() {
    _bankLoansBox.close();
    super.onClose();
  }
}
