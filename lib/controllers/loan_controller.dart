import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:list/models/loan.dart';

class LoanController extends GetxController {
  final Box<Loan> loanBox = Hive.box<Loan>('loans');
  final loans = <Loan>[].obs;
  final filteredLoans = <Loan>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadLoans();
  }

  void loadLoans() {
    try {
      isLoading.value = true;
      loans.value = loanBox.values.toList();
      filteredLoans.value = loans;
    } catch (e) {
      print('Error loading loans: $e');
      _showSnackbar('Error', 'Failed to load loans');
    } finally {
      isLoading.value = false;
    }
  }

  void addLoan(Loan loan) {
    try {
      // Check if serial number already exists
      if (loans.any(
        (existingLoan) => existingLoan.serialNumber == loan.serialNumber,
      )) {
        _showSnackbar('Error', 'Serial number already exists');
        return;
      }

      loanBox.add(loan);
      loans.add(loan);
      filteredLoans.value = loans;
      _showSnackbar('Success', 'Loan added successfully');
    } catch (e) {
      print('Error adding loan: $e');
      _showSnackbar('Error', 'Failed to add loan');
    }
  }

  void updateReceivedAmount(int index, double amount) {
    try {
      if (index < 0 || index >= loans.length) {
        _showSnackbar('Error', 'Invalid loan index');
        return;
      }

      final loan = loans[index];
      loan.amountReceived = amount;
      loan.save();
      loans[index] = loan;
      filteredLoans.value = loans;
      _showSnackbar('Success', 'Amount updated successfully');
    } catch (e) {
      print('Error updating amount: $e');
      _showSnackbar('Error', 'Failed to update amount');
    }
  }

  void updateReceivedAmountBySerial(String serialNumber, double amount) {
    try {
      final loanIndex = loans.indexWhere(
        (loan) => loan.serialNumber == serialNumber,
      );
      if (loanIndex == -1) {
        _showSnackbar('Error', 'Loan not found');
        return;
      }

      final loan = loans[loanIndex];
      loan.amountReceived = amount;
      loan.save();
      loans[loanIndex] = loan;
      filteredLoans.value = loans;
    } catch (e) {
      print('Error updating amount by serial: $e');
      _showSnackbar('Error', 'Failed to update amount');
    }
  }

  // New method to add partial repayment
  void addPartialRepayment(
    String serialNumber,
    double amount,
    DateTime repaymentDate,
  ) {
    try {
      final loanIndex = loans.indexWhere(
        (loan) => loan.serialNumber == serialNumber,
      );
      if (loanIndex == -1) {
        _showSnackbar('Error', 'Loan not found');
        return;
      }

      final loan = loans[loanIndex];

      // Validate repayment amount
      if (amount <= 0) {
        _showSnackbar('Error', 'Repayment amount must be greater than 0');
        return;
      }

      if (amount > loan.currentBalance) {
        _showSnackbar(
          'Error',
          'Repayment amount cannot exceed remaining balance',
        );
        return;
      }

      // Add partial repayment
      loan.addPartialRepayment(amount, repaymentDate);

      // Update the loan in the list
      loans[loanIndex] = loan;
      filteredLoans.value = loans;

      _showSnackbar('Success', 'Partial repayment added successfully');
    } catch (e) {
      print('Error adding partial repayment: $e');
      _showSnackbar('Error', 'Failed to add partial repayment');
    }
  }

  // Helper method to safely show snackbars
  void _showSnackbar(String title, String message) {
    try {
      // Close any existing snackbars first
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }

      // Add a small delay to ensure proper cleanup
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar(
          title,
          message,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    } catch (e) {
      print('Error showing snackbar: $e');
    }
  }

  // Method to get partial repayments for a loan
  List<PartialRepayment> getPartialRepayments(String serialNumber) {
    try {
      final loan = getLoanBySerial(serialNumber);
      return loan?.partialRepayments ?? [];
    } catch (e) {
      print('Error getting partial repayments: $e');
      return [];
    }
  }

  void refreshLoans() {
    loadLoans();
  }

  void search(String query) {
    try {
      if (query.isEmpty) {
        filteredLoans.value = loans;
      } else {
        final results = loans
            .where(
              (loan) =>
                  loan.name.toLowerCase().contains(query.toLowerCase()) ||
                  loan.serialNumber.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  loan.phone.contains(query) ||
                  loan.jewelleryName.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
        filteredLoans.value = results;
      }
    } catch (e) {
      print('Error searching loans: $e');
      filteredLoans.value = loans;
    }
  }

  void deleteLoanBySerial(String serialNumber) {
    try {
      final loanIndex = loans.indexWhere(
        (loan) => loan.serialNumber == serialNumber,
      );
      if (loanIndex == -1) {
        _showSnackbar('Error', 'Loan not found');
        return;
      }

      final loan = loans[loanIndex];
      loan.delete();
      loans.removeAt(loanIndex);
      filteredLoans.value = loans;
      _showSnackbar('Success', 'Loan deleted successfully');
    } catch (e) {
      print('Error deleting loan: $e');
      _showSnackbar('Error', 'Failed to delete loan');
    }
  }

  List<String> getUniqueCustomerNames() {
    try {
      final customerNames = loans.map((loan) => loan.name).toSet().toList();
      customerNames.sort();
      return customerNames;
    } catch (e) {
      print('Error getting customer names: $e');
      return [];
    }
  }

  List<Loan> getLoansByCustomerName(String customerName) {
    try {
      return loans
          .where(
            (loan) => loan.name.toLowerCase() == customerName.toLowerCase(),
          )
          .toList();
    } catch (e) {
      print('Error getting loans by customer: $e');
      return [];
    }
  }

  Map<String, List<Loan>> getLoansGroupedByCustomer() {
    try {
      final groupedLoans = <String, List<Loan>>{};
      for (final loan in loans) {
        if (groupedLoans.containsKey(loan.name)) {
          groupedLoans[loan.name]!.add(loan);
        } else {
          groupedLoans[loan.name] = [loan];
        }
      }
      return groupedLoans;
    } catch (e) {
      print('Error grouping loans: $e');
      return {};
    }
  }

  double getTotalDueAmountForCustomer(String customerName) {
    try {
      final customerLoans = getLoansByCustomerName(customerName);
      return customerLoans.fold(0.0, (sum, loan) => sum + loan.dueAmount);
    } catch (e) {
      print('Error calculating total due: $e');
      return 0.0;
    }
  }

  double getTotalCompoundInterestForCustomer(String customerName) {
    try {
      final customerLoans = getLoansByCustomerName(customerName);
      return customerLoans.fold(
        0.0,
        (sum, loan) => sum + loan.compoundInterest,
      );
    } catch (e) {
      print('Error calculating compound interest: $e');
      return 0.0;
    }
  }

  double getTotalFixedInterestForCustomer(String customerName) {
    try {
      final customerLoans = getLoansByCustomerName(customerName);
      return customerLoans.fold(
        0.0,
        (sum, loan) => sum + loan.agreedPeriodInterest,
      );
    } catch (e) {
      print('Error calculating fixed interest: $e');
      return 0.0;
    }
  }

  double getTotalImmediateDueForCustomer(String customerName) {
    try {
      final customerLoans = getLoansByCustomerName(customerName);
      return customerLoans.fold(
        0.0,
        (sum, loan) => sum + loan.immediateTotalDue,
      );
    } catch (e) {
      print('Error calculating immediate due: $e');
      return 0.0;
    }
  }

  double getTotalOverdueInterestForCustomer(String customerName) {
    try {
      final customerLoans = getLoansByCustomerName(customerName);
      return customerLoans.fold(0.0, (sum, loan) => sum + loan.overdueInterest);
    } catch (e) {
      print('Error calculating overdue interest: $e');
      return 0.0;
    }
  }

  int getTotalOverdueDaysForCustomer(String customerName) {
    try {
      final customerLoans = getLoansByCustomerName(customerName);
      return customerLoans.fold(0, (sum, loan) => sum + loan.overdueDays);
    } catch (e) {
      print('Error calculating overdue days: $e');
      return 0;
    }
  }

  bool isCustomerOverdue(String customerName) {
    try {
      final customerLoans = getLoansByCustomerName(customerName);
      return customerLoans.any((loan) => loan.isOverdue);
    } catch (e) {
      print('Error checking overdue status: $e');
      return false;
    }
  }

  // Get loan by serial number
  Loan? getLoanBySerial(String serialNumber) {
    try {
      final loanIndex = loans.indexWhere(
        (loan) => loan.serialNumber == serialNumber,
      );
      return loanIndex != -1 ? loans[loanIndex] : null;
    } catch (e) {
      print('Error getting loan by serial: $e');
      return null;
    }
  }

  // Get total statistics
  double getTotalLoansAmount() {
    try {
      return loans.fold(0.0, (sum, loan) => sum + loan.amountGiven);
    } catch (e) {
      print('Error calculating total loans amount: $e');
      return 0.0;
    }
  }

  double getTotalReceivedAmount() {
    try {
      return loans.fold(0.0, (sum, loan) => sum + loan.amountReceived);
    } catch (e) {
      print('Error calculating total received amount: $e');
      return 0.0;
    }
  }

  double getTotalDueAmount() {
    try {
      return loans.fold(0.0, (sum, loan) => sum + loan.dueAmount);
    } catch (e) {
      print('Error calculating total due amount: $e');
      return 0.0;
    }
  }

  int getTotalLoansCount() {
    return loans.length;
  }

  int getOverdueLoansCount() {
    try {
      return loans.where((loan) => loan.isOverdue).length;
    } catch (e) {
      print('Error counting overdue loans: $e');
      return 0;
    }
  }

  // Refresh loan calculations and notify UI
  void refreshLoanCalculations() {
    try {
      // Force UI update by reassigning the list
      final currentLoans = List<Loan>.from(loans);
      loans.value = currentLoans;
      filteredLoans.value = currentLoans;
    } catch (e) {
      print('Error refreshing loan calculations: $e');
    }
  }

  // Get loan with updated calculations
  Loan? getUpdatedLoan(String serialNumber) {
    try {
      final loan = getLoanBySerial(serialNumber);
      if (loan != null) {
        // Force recalculation by accessing properties
        loan.dueAmount;
        loan.compoundInterest;
        loan.isOverdue;
        return loan;
      }
      return null;
    } catch (e) {
      print('Error getting updated loan: $e');
      return null;
    }
  }

  // Calculate early repayment amount for a loan (updated for new rules)
  double calculateEarlyRepaymentAmount(Loan loan) {
    try {
      final daysPassed = loan.daysPassed;

      // Rule 1: Minimum one-month interest (30 days) for loans up to 30 days
      if (loan.duration <= 30) {
        final effectiveDays = daysPassed <= 30 ? 30 : daysPassed;
        final actualInterest =
            (loan.amountGiven * loan.interestRate) / 100 * effectiveDays;
        return loan.amountGiven + actualInterest;
      }

      // Rule 2: For loans longer than 30 days, use actual days passed
      final actualInterest =
          (loan.amountGiven * loan.interestRate) / 100 * daysPassed;
      return loan.amountGiven + actualInterest;
    } catch (e) {
      print('Error calculating early repayment amount: $e');
      return loan.immediateTotalDue;
    }
  }

  // Calculate early repayment interest for a loan (updated for new rules)
  double calculateEarlyRepaymentInterest(Loan loan) {
    try {
      final daysPassed = loan.daysPassed;

      // Rule 1: Minimum one-month interest (30 days) for loans up to 30 days
      if (loan.duration <= 30) {
        final effectiveDays = daysPassed <= 30 ? 30 : daysPassed;
        return (loan.amountGiven * loan.interestRate) / 100 * effectiveDays;
      }

      // Rule 2: For loans longer than 30 days, use actual days passed
      return (loan.amountGiven * loan.interestRate) / 100 * daysPassed;
    } catch (e) {
      print('Error calculating early repayment interest: $e');
      return loan.agreedPeriodInterest;
    }
  }

  // Calculate early repayment due amount for a loan
  double calculateEarlyRepaymentDueAmount(Loan loan) {
    try {
      final earlyRepaymentAmount = calculateEarlyRepaymentAmount(loan);
      return earlyRepaymentAmount - loan.amountReceived;
    } catch (e) {
      print('Error calculating early repayment due amount: $e');
      return loan.dueAmount;
    }
  }

  // Get total early repayment amount for a customer
  double getTotalEarlyRepaymentAmountForCustomer(String customerName) {
    try {
      final customerLoans = getLoansByCustomerName(customerName);
      return customerLoans.fold(
        0.0,
        (sum, loan) => sum + calculateEarlyRepaymentAmount(loan),
      );
    } catch (e) {
      print('Error calculating total early repayment amount: $e');
      return 0.0;
    }
  }
}
