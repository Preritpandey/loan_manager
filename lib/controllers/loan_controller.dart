import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:list/models/loan.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:intl/intl.dart';

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

  // Get filtered loans for display
  List<Loan> getFilteredLoans() {
    return filteredLoans;
  }

  // Check if search is active
  bool isSearchActive() {
    return filteredLoans.length != loans.length;
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
      // Use filteredLoans instead of loans for search functionality
      for (final loan in filteredLoans) {
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

  // Export all loan data to PDF
  Future<void> exportToPDF() async {
    try {
      isLoading.value = true;

      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnackbar('Error', 'Storage permission is required to save PDF');
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
      final output = await getTemporaryDirectory();
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
}
