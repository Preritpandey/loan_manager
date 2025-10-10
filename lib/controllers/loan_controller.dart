import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:list/models/loan.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class LoanController extends GetxController {
  final Box<Loan> loanBox = Hive.box<Loan>('loans');
  final loans = <Loan>[].obs;
  final filteredLoans = <Loan>[].obs;
  final searchSuggestions = <String>[].obs;
  final isLoading = false.obs;
  final isSearchActive = false.obs;
  final hasExplicitSearch = false.obs;

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
      isSearchActive.value = false;
      hasExplicitSearch.value = false;

      // Print all loans to console for debugging
      printAllLoans();

      // Verify customer grouping
      verifyCustomerGrouping();
    } catch (e) {
      print('Error loading loans: $e');
      _showSnackbar('Error', 'Failed to load loans');
    } finally {
      isLoading.value = false;
    }
  }

  void addLoan(Loan loan) {
    try {
      // Check for duplicate loans: same customer name + same jewellery name + same serial number
      // This allows the same customer to have multiple loans with different collateral
      if (loans.any(
        (existingLoan) =>
            existingLoan.name.trim().toLowerCase() ==
                loan.name.trim().toLowerCase() &&
            existingLoan.serialNumber == loan.serialNumber &&
            existingLoan.jewelleryName == loan.jewelleryName,
      )) {
        _showSnackbar(
          'Error',
          'A loan with this customer, serial number, and jewellery already exists',
        );
        return;
      }

      loanBox.add(loan);
      loans.add(loan);
      filteredLoans.value = loans;

      // Force UI refresh to update grouping
      refreshLoanCalculations();

      // Print all loans to console for debugging
      printAllLoans();

      _showSnackbar('Success', 'Loan added successfully');

      // Navigate back to loan home page
      Get.offAllNamed('/home');
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

      // Force UI update
      update();
    } catch (e) {
      print('Error updating amount by serial: $e');
      _showSnackbar('Error', 'Failed to update amount');
    }
  }

  void updateReceivedAmountByLoanId(String loanId, double amount) {
    try {
      final loanIndex = loans.indexWhere((loan) => loan.loanId == loanId);
      if (loanIndex == -1) {
        _showSnackbar('Error', 'Loan not found');
        return;
      }

      final loan = loans[loanIndex];
      loan.amountReceived = amount;
      loan.save();
      loans[loanIndex] = loan;
      filteredLoans.value = loans;

      // Force UI update
      update();
    } catch (e) {
      print('Error updating amount by loan ID: $e');
      _showSnackbar('Error', 'Failed to update amount');
    }
  }

  // New method to add partial repayment with validation
  void addPartialRepayment(String serialNumber, double amount, DateTime date) {
    try {
      final loanIndex = loans.indexWhere(
        (loan) => loan.serialNumber == serialNumber,
      );
      if (loanIndex == -1) {
        _showSnackbar('Error', 'Loan not found');
        return;
      }

      if (amount <= 0) {
        _showSnackbar('Error', 'Repayment amount must be positive');
        return;
      }

      final loan = loans[loanIndex];

      // Clamp future-dated repayments to today so the change reflects immediately in dueAmount
      final effectiveDate = date.isAfter(DateTime.now()) ? DateTime.now() : date;

      // Compute outstanding due as of the effective repayment date (no settlement enforcement)
      final outstanding = loan.outstandingDueAt(effectiveDate, forSettlement: false);

      // Do not allow overpayment; prevent negative balances
      if (amount - outstanding > 0.005) {
        // small epsilon for floating point
        _showSnackbar(
          'Error',
          'Repayment exceeds outstanding due (NPR ${outstanding.toStringAsFixed(2)})',
        );
        return;
      }

      // If amount is slightly more due to rounding, clamp to outstanding
      final adjustedAmount = amount > outstanding ? outstanding : amount;

      loan.addPartialRepayment(adjustedAmount, effectiveDate);
      loan.save();
      loans[loanIndex] = loan;
      filteredLoans.value = loans;
    } catch (e) {
      print('Error adding partial repayment: $e');
      _showSnackbar('Error', 'Failed to add partial repayment');
    }
  }

  // New: add partial repayment using settlement rules (min 30-day enforcement)
  void addPartialRepaymentForSettlement(
    String serialNumber,
    double amount,
    DateTime date,
  ) {
    try {
      final loanIndex = loans.indexWhere(
        (loan) => loan.serialNumber == serialNumber,
      );
      if (loanIndex == -1) {
        _showSnackbar('Error', 'Loan not found');
        return;
      }

      if (amount <= 0) {
        _showSnackbar('Error', 'Repayment amount must be positive');
        return;
      }

      final loan = loans[loanIndex];

      // Clamp future-dated repayments to today so the change reflects immediately in dueAmount
      final effectiveDate = date.isAfter(DateTime.now()) ? DateTime.now() : date;

      // Settlement due allows min-30 enforcement
      final outstanding = loan.outstandingDueAt(effectiveDate, forSettlement: true);

      // Do not allow overpayment; prevent negative balances
      if (amount - outstanding > 0.005) {
        _showSnackbar(
          'Error',
          'Repayment exceeds outstanding due (NPR ${outstanding.toStringAsFixed(2)})',
        );
        return;
      }

      final adjustedAmount = amount > outstanding ? outstanding : amount;

      loan.addPartialRepayment(adjustedAmount, effectiveDate);
      loan.save();
      loans[loanIndex] = loan;
      filteredLoans.value = loans;
    } catch (e) {
      print('Error adding partial repayment (settlement): $e');
      _showSnackbar('Error', 'Failed to add partial repayment');
    }
  }

  // New: add top-up to existing loan (increase principal)
  void addTopUp(String serialNumber, double amount, DateTime date) {
    try {
      if (amount <= 0) {
        _showSnackbar('Error', 'Top-up amount must be positive');
        return;
      }
      final loanIndex = loans.indexWhere(
        (loan) => loan.serialNumber == serialNumber,
      );
      if (loanIndex == -1) {
        _showSnackbar('Error', 'Loan not found');
        return;
      }
      final loan = loans[loanIndex];
      // Clamp future-dated top-ups to today so the change reflects immediately in dueAmount
      final effectiveDate = date.isAfter(DateTime.now()) ? DateTime.now() : date;
      loan.addTopUp(amount, effectiveDate);
      loan.save();
      loans[loanIndex] = loan;
      filteredLoans.value = loans;
      refreshLoanCalculations();
    } catch (e) {
      print('Error adding top up: $e');
      _showSnackbar('Error', 'Failed to add top-up');
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

  // Get partial repayments for a loan
  List<PartialRepayment> getPartialRepayments(String serialNumber) {
    try {
      final loan = loans.firstWhere(
        (loan) => loan.serialNumber == serialNumber,
      );
      return loan.partialRepayments;
    } catch (e) {
      print('Error getting partial repayments: $e');
      return [];
    }
  }

  void refreshLoans() {
    loadLoans();
  }

  // Generate search suggestions based on query
  void generateSearchSuggestions(String query) {
    if (query.isEmpty) {
      searchSuggestions.clear();
      return;
    }

    try {
      final suggestions = <String>{};
      final queryLower = query.toLowerCase();

      // Add customer name suggestions
      for (final loan in loans) {
        if (loan.name.toLowerCase().contains(queryLower)) {
          suggestions.add(loan.name);
        }
      }

      // Add serial number suggestions
      for (final loan in loans) {
        if (loan.serialNumber.toLowerCase().contains(queryLower)) {
          suggestions.add(loan.serialNumber);
        }
      }

      // Add phone number suggestions
      for (final loan in loans) {
        if (loan.phone.contains(query)) {
          suggestions.add(loan.phone);
        }
      }

      // Add jewellery name suggestions
      for (final loan in loans) {
        if (loan.jewelleryName.toLowerCase().contains(queryLower)) {
          suggestions.add(loan.jewelleryName);
        }
      }

      // Limit suggestions to 10 items and sort
      searchSuggestions.value = suggestions.take(10).toList()..sort();
    } catch (e) {
      print('Error generating search suggestions: $e');
      searchSuggestions.clear();
    }
  }

  // Real-time search with suggestions
  void search(String query) {
    try {
      if (query.isEmpty) {
        filteredLoans.value = loans;
        isSearchActive.value = false;
        hasExplicitSearch.value = false;
        searchSuggestions.clear();
      } else {
        isSearchActive.value = true;
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

        // Generate suggestions for real-time search
        generateSearchSuggestions(query);
      }
    } catch (e) {
      print('Error searching loans: $e');
      filteredLoans.value = loans;
    }
  }

  // Explicit search (when user presses Enter or Search button)
  void performExplicitSearch(String query) {
    search(query);
    hasExplicitSearch.value = true;
  }

  // Clear search and return to all loans
  void clearSearch() {
    filteredLoans.value = loans;
    isSearchActive.value = false;
    hasExplicitSearch.value = false;
    searchSuggestions.clear();
  }

  // Get filtered loans for display
  List<Loan> getFilteredLoans() {
    return filteredLoans;
  }

  // Check if search is active
  bool getIsSearchActive() {
    return isSearchActive.value;
  }

  // Check if we should show "no results" message
  bool shouldShowNoResults() {
    return hasExplicitSearch.value && filteredLoans.isEmpty && !isLoading.value;
  }

  // Check if we should show all loans (no search active)
  bool shouldShowAllLoans() {
    return !isSearchActive.value && !hasExplicitSearch.value;
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

      // Navigate back to loan home page
      Get.offAllNamed('/home');

      // Note: Success snackbar will be shown by the calling controller
    } catch (e) {
      print('Error deleting loan: $e');
      _showSnackbar('Error', 'Failed to delete loan');
    }
  }

  List<String> getUniqueCustomerNames() {
    try {
      final customerNames = <String>{};
      for (final loan in loans) {
        final normalizedName = loan.name.trim().toLowerCase();
        // Find if we already have a name with same normalized form
        bool found = false;
        for (final existingName in customerNames) {
          if (existingName.trim().toLowerCase() == normalizedName) {
            found = true;
            break;
          }
        }
        if (!found) {
          customerNames.add(
            loan.name.trim(),
          ); // Use trimmed original name to preserve formatting
        }
      }
      final sortedNames = customerNames.toList()..sort();
      return sortedNames;
    } catch (e) {
      print('Error getting customer names: $e');
      return [];
    }
  }

  // Get the most recent loan for a customer (for loan reissue)
  Loan? getMostRecentLoanForCustomer(String customerName) {
    try {
      final customerLoans = getLoansByCustomerName(customerName);
      if (customerLoans.isEmpty) return null;

      // Sort by date (most recent first)
      customerLoans.sort((a, b) => b.date.compareTo(a.date));
      return customerLoans.first;
    } catch (e) {
      print('Error getting most recent loan: $e');
      return null;
    }
  }

  // Get collateral info for customer (for loan reissue)
  Map<String, dynamic>? getLastCollateralInfo(String customerName) {
    try {
      final recentLoan = getMostRecentLoanForCustomer(customerName);
      if (recentLoan == null) return null;

      return {
        'serialNumber': recentLoan.serialNumber,
        'type': recentLoan.type,
        'jewelleryName': recentLoan.jewelleryName,
        'address': recentLoan.address,
        'phone': recentLoan.phone,
      };
    } catch (e) {
      print('Error getting collateral info: $e');
      return null;
    }
  }

  List<Loan> getLoansByCustomerName(String customerName) {
    try {
      final normalizedCustomerName = customerName.trim().toLowerCase();
      return loans
          .where(
            (loan) => loan.name.trim().toLowerCase() == normalizedCustomerName,
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
      // Use filteredLoans instead of loans for search functionality
      for (final loan in filteredLoans) {
        // Normalize customer name for proper grouping
        final normalizedName = loan.name.trim().toLowerCase();

        // Find existing group with same normalized name
        String? existingKey;
        for (final key in groupedLoans.keys) {
          if (key.trim().toLowerCase() == normalizedName) {
            existingKey = key;
            break;
          }
        }

        if (existingKey != null) {
          // Add to existing group
          groupedLoans[existingKey]!.add(loan);
        } else {
          // Create new group using the original name (preserving case and formatting)
          groupedLoans[loan.name.trim()] = [loan];
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

  // Get loan by loan ID
  Loan? getLoanByLoanId(String loanId) {
    try {
      final loanIndex = loans.indexWhere((loan) => loan.loanId == loanId);
      return loanIndex != -1 ? loans[loanIndex] : null;
    } catch (e) {
      print('Error getting loan by loan ID: $e');
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

  // Helper: get outstanding balance (principal + accrued interest) as of now
  double getOutstandingDue(String serialNumber) {
    final loan = getLoanBySerial(serialNumber);
    if (loan == null) return 0.0;
    return loan.outstandingDueAt(DateTime.now(), forSettlement: false);
  }

  // New: outstanding due for settlement now (with min 30-day enforcement)
  double getOutstandingDueForSettlement(String serialNumber) {
    final loan = getLoanBySerial(serialNumber);
    if (loan == null) return 0.0;
    return loan.outstandingDueAt(DateTime.now(), forSettlement: true);
  }

  // Helper: get total interest paid so far for a loan
  double getTotalInterestPaid(String serialNumber) {
    final loan = getLoanBySerial(serialNumber);
    if (loan == null) return 0.0;
    return loan.totalInterestPaidSoFar;
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

  // Calculate early repayment amount for a loan using ledger and min-30 rule
  double calculateEarlyRepaymentAmount(Loan loan) {
    try {
      return loan.outstandingDueAt(DateTime.now(), forSettlement: true);
    } catch (e) {
      print('Error calculating early repayment amount: $e');
      return loan.dueAmount;
    }
  }

  // Calculate early repayment interest (portion of outstanding that is interest)
  double calculateEarlyRepaymentInterest(Loan loan) {
    try {
      // Interest due is compoundInterest under our model
      return loan.compoundInterest;
    } catch (e) {
      print('Error calculating early repayment interest: $e');
      return loan.agreedPeriodInterest;
    }
  }

  // Calculate early repayment due amount for a loan
  double calculateEarlyRepaymentDueAmount(Loan loan) {
    try {
      return calculateEarlyRepaymentAmount(loan);
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

  // Method to print raw loan data to console for debugging
  void printAllLoans() {
    print('\n=== RAW LOAN DATA FROM HIVE ===');
    print('Total loans in database: ${loanBox.length}');
    print('Total loans in memory: ${loans.length}');
    print('---');

    if (loanBox.isEmpty) {
      print('No loans found in database.');
      return;
    }

    // Print raw data from Hive box
    for (int i = 0; i < loanBox.length; i++) {
      final loan = loanBox.getAt(i);
      if (loan != null) {
        print('Raw Loan ${i + 1} (Hive Index: $i):');
        print('  name: "${loan.name}"');
        print('  phone: "${loan.phone}"');
        print('  address: "${loan.address}"');
        print('  serialNumber: "${loan.serialNumber}"');
        print('  jewelleryName: "${loan.jewelleryName}"');
        print('  type: "${loan.type}"');
        print('  amountGiven: ${loan.amountGiven}');
        print('  amountReceived: ${loan.amountReceived}');
        print('  interestRate: ${loan.interestRate}');
        print('  duration: ${loan.duration}');
        print('  date: ${loan.date}');
        print('  nepaliDateString: "${loan.nepaliDateString}"');
        print('  loanId: "${loan.loanId}"');
        print('  description: "${loan.description}"');
        print('  partialRepayments: ${loan.partialRepayments.length} items');
        for (int j = 0; j < loan.partialRepayments.length; j++) {
          final repayment = loan.partialRepayments[j];
          print(
            '    Repayment $j: amount=${repayment.amount}, date=${repayment.date}, daysSinceLoan=${repayment.daysSinceLoan}',
          );
        }
        print('  ---');
      }
    }

    print('\n=== CUSTOMER GROUPING ANALYSIS ===');
    final groupedLoans = getLoansGroupedByCustomer();
    print('Grouped customers: ${groupedLoans.length}');
    print('---');

    if (groupedLoans.isEmpty) {
      print('No customers found after grouping.');
      return;
    }

    // Print grouped data in the requested format
    groupedLoans.forEach((customerName, customerLoans) {
      print('Customer: "$customerName" (${customerLoans.length} loans)');
      print('---');

      for (int i = 0; i < customerLoans.length; i++) {
        final loan = customerLoans[i];
        print(
          'Loan ${i + 1} → Serial: "${loan.serialNumber}" | Jewellery: "${loan.jewelleryName}" | Amount: ${loan.amountGiven} | Interest: ${loan.interestRate}%',
        );
        print('  Phone: ${loan.phone}');
        print('  Address: ${loan.address}');
        print('  Date: ${loan.nepaliDateString}');
        print('  Due Amount: NPR ${loan.dueAmount.toStringAsFixed(2)}');
        print('  ---');
      }
    });

    print('\n=== GROUPING VERIFICATION ===');
    print('Total individual loans: ${loans.length}');
    print('Total grouped customers: ${groupedLoans.length}');
    int totalLoansInGroups = groupedLoans.values.fold(
      0,
      (sum, loanList) => sum + loanList.length,
    );
    print('Total loans in groups: $totalLoansInGroups');
    print(
      'Grouping successful: ${loans.length == totalLoansInGroups ? "✅ YES" : "❌ NO"}',
    );
    print('========================\n');
  }

  // Method to verify and fix customer grouping issues
  void verifyCustomerGrouping() {
    print('\n=== CUSTOMER GROUPING VERIFICATION ===');

    // Get all unique customer names
    final allCustomerNames = <String>{};
    final nameVariations = <String, List<String>>{};

    for (final loan in loans) {
      final name = loan.name.trim();
      final normalizedName = name.toLowerCase();

      allCustomerNames.add(name);

      // Track variations of the same name
      if (nameVariations.containsKey(normalizedName)) {
        if (!nameVariations[normalizedName]!.contains(name)) {
          nameVariations[normalizedName]!.add(name);
        }
      } else {
        nameVariations[normalizedName] = [name];
      }
    }

    print('Total unique names (case-sensitive): ${allCustomerNames.length}');
    print('Total unique names (case-insensitive): ${nameVariations.length}');

    // Check for name variations that should be grouped
    nameVariations.forEach((normalizedName, variations) {
      if (variations.length > 1) {
        print('⚠️  Name variations found for "$normalizedName":');
        for (final variation in variations) {
          print('    - "$variation"');
        }
      }
    });

    // Test grouping function
    final groupedLoans = getLoansGroupedByCustomer();
    print('\nGrouping Results:');
    print('Customers after grouping: ${groupedLoans.length}');

    groupedLoans.forEach((customerName, customerLoans) {
      print('Customer: "$customerName" (${customerLoans.length} loans)');
      for (final loan in customerLoans) {
        print(
          '  - Serial: "${loan.serialNumber}" | Jewellery: "${loan.jewelleryName}"',
        );
      }
    });

    print('========================\n');
  }

  // Method to clean up customer names (normalize them)
  void normalizeCustomerNames() {
    print('\n=== NORMALIZING CUSTOMER NAMES ===');

    bool hasChanges = false;
    final nameMapping = <String, String>{};

    // Find all name variations and create mapping
    final nameVariations = <String, List<String>>{};

    for (final loan in loans) {
      final name = loan.name.trim();
      final normalizedName = name.toLowerCase();

      if (nameVariations.containsKey(normalizedName)) {
        if (!nameVariations[normalizedName]!.contains(name)) {
          nameVariations[normalizedName]!.add(name);
        }
      } else {
        nameVariations[normalizedName] = [name];
      }
    }

    // Create mapping to standardize names
    nameVariations.forEach((normalizedName, variations) {
      if (variations.length > 1) {
        // Use the first variation as the standard
        final standardName = variations.first;
        for (final variation in variations) {
          if (variation != standardName) {
            nameMapping[variation] = standardName;
          }
        }
      }
    });

    // Apply the mapping
    for (final loan in loans) {
      final currentName = loan.name.trim();
      if (nameMapping.containsKey(currentName)) {
        final newName = nameMapping[currentName]!;
        print('Normalizing: "$currentName" → "$newName"');
        loan.name = newName;
        loan.save();
        hasChanges = true;
      }
    }

    if (hasChanges) {
      print('✅ Customer names normalized successfully');
      // Reload loans to reflect changes
      loadLoans();
    } else {
      print('✅ No name normalization needed');
    }

    print('========================\n');
  }

  // Helper method to request appropriate storage permissions
  Future<bool> _requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        // For Android 11+ (API 30+), check MANAGE_EXTERNAL_STORAGE first
        if (await Permission.manageExternalStorage.isGranted) {
          return true;
        }

        // Try requesting MANAGE_EXTERNAL_STORAGE
        final manageStorageStatus = await Permission.manageExternalStorage
            .request();
        if (manageStorageStatus.isGranted) {
          return true;
        }

        // If MANAGE_EXTERNAL_STORAGE is denied, try regular storage permissions
        final storagePermissions = [
          Permission.storage,
          if (Platform.isAndroid) Permission.photos,
        ];

        // Check if any storage permission is already granted
        for (final permission in storagePermissions) {
          if (await permission.isGranted) {
            return true;
          }
        }

        // Request storage permissions
        final results = await storagePermissions.request();
        return results.values.any((status) => status.isGranted);
      } else {
        // For iOS and other platforms
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      print('Error requesting storage permissions: $e');
      return false;
    }
  }

  // Export all loan data to PDF
  Future<void> exportToPDF() async {
    try {
      isLoading.value = true;

      // Check and request appropriate permissions
      bool permissionGranted = await _requestStoragePermissions();

      if (!permissionGranted) {
        _showSnackbar(
          'Error',
          'Storage permission is required to save PDF. Please grant permission in app settings.',
        );
        return;
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Loan Manager Report',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Generated on: ${DateTime.now().toString().substring(0, 19)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Text(
                        'Total Loans: ${loans.length}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Summary Section
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 20, bottom: 20),
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Total Amount Given',
                            'NPR ${getTotalLoansAmount().toStringAsFixed(2)}',
                            PdfColors.blue,
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Total Amount Received',
                            'NPR ${getTotalReceivedAmount().toStringAsFixed(2)}',
                            PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Total Due Amount',
                            'NPR ${getTotalDueAmount().toStringAsFixed(2)}',
                            PdfColors.red,
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Overdue Loans',
                            '${getOverdueLoansCount()}',
                            PdfColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Customer Loans Section
              ..._buildCustomerLoansSection(),
            ];
          },
        ),
      );

      // Save PDF to device
      Directory? output;
      try {
        // Try to save to Downloads directory (doesn't require permissions on modern Android)
        if (Platform.isAndroid) {
          output = Directory('/storage/emulated/0/Download');
          if (!await output.exists()) {
            // Fallback to external storage directory
            output = await getExternalStorageDirectory();
            output ??= await getApplicationDocumentsDirectory();
          }
        } else {
          // For iOS and other platforms
          output = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        print('Error getting storage directory: $e');
        output = await getTemporaryDirectory();
      }

      final file = File(
        '${output.path}/loan_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      // Open the PDF file
      await OpenFile.open(file.path);

      _showSnackbar('Success', 'PDF exported successfully and opened');
    } catch (e) {
      print('Error exporting PDF: $e');
      _showSnackbar('Error', 'Failed to export PDF: $e');
    } finally {
      isLoading.value = false;
    }
  }

  pw.Widget _buildSummaryBox(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildCustomerLoansSection() {
    final groupedLoans = getLoansGroupedByCustomer();
    final widgets = <pw.Widget>[];

    groupedLoans.forEach((customerName, customerLoans) {
      final totalDue = getTotalDueAmountForCustomer(customerName);
      final isOverdue = isCustomerOverdue(customerName);

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: isOverdue ? PdfColors.red50 : PdfColors.white,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(
              color: isOverdue ? PdfColors.red : PdfColors.grey300,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Customer Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      customerName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOverdue)
                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red,
                        borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(12),
                        ),
                      ),
                      child: pw.Text(
                        'OVERDUE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  pw.Container(
                    padding: pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                    ),
                    child: pw.Text(
                      '${customerLoans.length} loan${customerLoans.length > 1 ? 's' : ''}',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),

              // Customer Summary
              pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildCustomerSummaryItem(
                      'Total Given',
                      'NPR ${customerLoans.fold(0.0, (sum, loan) => sum + loan.amountGiven).toStringAsFixed(2)}',
                    ),
                  ),
                  pw.Expanded(
                    child: _buildCustomerSummaryItem(
                      'Total Received',
                      'NPR ${customerLoans.fold(0.0, (sum, loan) => sum + loan.amountReceived).toStringAsFixed(2)}',
                    ),
                  ),
                  pw.Expanded(
                    child: _buildCustomerSummaryItem(
                      'Total Due',
                      'NPR ${totalDue.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 15),

              // Individual Loans Table
              pw.Text(
                'Individual Loans:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              // Table Header
              pw.Container(
                padding: pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Serial',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'Jewellery',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Given',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Received',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Due',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Status',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Table Rows
              ...customerLoans
                  .map(
                    (loan) => pw.Container(
                      margin: pw.EdgeInsets.only(top: 2),
                      padding: pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: loan.isOverdue
                            ? PdfColors.red50
                            : PdfColors.white,
                        borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(loan.serialNumber),
                          ),
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(loan.jewelleryName),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'NPR ${loan.amountGiven.toStringAsFixed(2)}',
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'NPR ${loan.amountReceived.toStringAsFixed(2)}',
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'NPR ${loan.dueAmount.toStringAsFixed(2)}',
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              loan.isOverdue ? 'Overdue' : 'Active',
                              style: pw.TextStyle(
                                color: loan.isOverdue
                                    ? PdfColors.red
                                    : PdfColors.green,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),

              pw.SizedBox(height: 10),
              pw.Text(
                'Phone: ${customerLoans.first.phone}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      );
    });

    return widgets;
  }

  pw.Widget _buildCustomerSummaryItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  // Export specific customer's loans to PDF
  Future<void> exportCustomerLoansToPDF(String customerName) async {
    try {
      isLoading.value = true;

      // Check and request appropriate permissions
      bool permissionGranted = await _requestStoragePermissions();

      if (!permissionGranted) {
        _showSnackbar(
          'Error',
          'Storage permission is required to save PDF. Please grant permission in app settings.',
        );
        return;
      }

      // Get customer's loans
      final customerLoans = getLoansByCustomerName(customerName);
      if (customerLoans.isEmpty) {
        _showSnackbar('Error', 'No loans found for customer: $customerName');
        return;
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add pages to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Customer Loan Report',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Customer: $customerName',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                        pw.Text(
                          'Generated on: ${DateTime.now().toString().substring(0, 19)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Text(
                        '${customerLoans.length} loan${customerLoans.length > 1 ? 's' : ''}',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Customer Summary Section
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 20, bottom: 20),
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Customer Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Total Amount Given',
                            'NPR ${customerLoans.fold(0.0, (sum, loan) => sum + loan.amountGiven).toStringAsFixed(2)}',
                            PdfColors.blue,
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Total Amount Received',
                            'NPR ${customerLoans.fold(0.0, (sum, loan) => sum + loan.amountReceived).toStringAsFixed(2)}',
                            PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Total Due Amount',
                            'NPR ${getTotalDueAmountForCustomer(customerName).toStringAsFixed(2)}',
                            PdfColors.red,
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Overdue Status',
                            isCustomerOverdue(customerName) ? 'Yes' : 'No',
                            isCustomerOverdue(customerName)
                                ? PdfColors.red
                                : PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Customer Information
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Customer Information',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Name: $customerName'),
                    pw.Text('Phone: ${customerLoans.first.phone}'),
                    pw.Text('Address: ${customerLoans.first.address}'),
                  ],
                ),
              ),

              // Individual Loans Section
              ..._buildCustomerLoansSectionForPDF(customerName, customerLoans),
            ];
          },
        ),
      );

      // Save PDF to device
      Directory? output;
      try {
        // Try to save to Downloads directory (doesn't require permissions on modern Android)
        if (Platform.isAndroid) {
          output = Directory('/storage/emulated/0/Download');
          if (!await output.exists()) {
            // Fallback to external storage directory
            output = await getExternalStorageDirectory();
            output ??= await getApplicationDocumentsDirectory();
          }
        } else {
          // For iOS and other platforms
          output = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        print('Error getting storage directory: $e');
        output = await getTemporaryDirectory();
      }

      final file = File(
        '${output.path}/customer_loans_${customerName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      // Open the PDF file
      await OpenFile.open(file.path);

      _showSnackbar('Success', 'Customer PDF exported successfully and opened');
    } catch (e) {
      print('Error exporting customer PDF: $e');
      _showSnackbar('Error', 'Failed to export customer PDF: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<pw.Widget> _buildCustomerLoansSectionForPDF(
    String customerName,
    List<Loan> customerLoans,
  ) {
    final widgets = <pw.Widget>[];
    final isOverdue = isCustomerOverdue(customerName);

    widgets.add(
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: isOverdue ? PdfColors.red50 : PdfColors.white,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(
            color: isOverdue ? PdfColors.red : PdfColors.grey300,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Individual Loans Table
            pw.Text(
              'Individual Loans:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            // Table Header
            pw.Container(
              padding: pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Serial',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Jewellery',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Given',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Received',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Due',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Status',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Table Rows
            ...customerLoans
                .map(
                  (loan) => pw.Container(
                    margin: pw.EdgeInsets.only(top: 2),
                    padding: pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: loan.isOverdue ? PdfColors.red50 : PdfColors.white,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 2, child: pw.Text(loan.serialNumber)),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(loan.jewelleryName),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'NPR ${loan.amountGiven.toStringAsFixed(2)}',
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'NPR ${loan.amountReceived.toStringAsFixed(2)}',
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'NPR ${loan.dueAmount.toStringAsFixed(2)}',
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            loan.isOverdue ? 'Overdue' : 'Active',
                            style: pw.TextStyle(
                              color: loan.isOverdue
                                  ? PdfColors.red
                                  : PdfColors.green,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );

    return widgets;
  }
}
