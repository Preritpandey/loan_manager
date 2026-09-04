import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:list/models/loan.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:io';
import 'package:list/utils/nepali_date_utils.dart';
import 'package:list/models/loan_event.dart';

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

  // Record a performed event (stored separately) for strict 'performed today' filtering
  void _recordEvent({
    required String name,
    required String serial,
    required String type,
    required DateTime recordedDate,
    required double amount,
    String? description,
    String? jewelleryName,
    double? dueAfter,
    bool isInterestOnly = false,
  }) {
    // Ensure performedAt is set to the current date (midnight) for proper filtering
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Set description based on payment type
    String? enhancedDescription = description;
    if (type == 'repayment') {
      if (description == null || description == 'Payment received' || description == 'Overall payment received') {
        enhancedDescription = isInterestOnly ? 'Interest Collection' : 'Overall Payment';
      } else if (description == 'Interest payment received' || description.contains('Interest')) {
        enhancedDescription = 'Interest Collection';
      } else if (description.contains('Principal')) {
        enhancedDescription = 'Principal Payment';
      } else if (description.contains('Full Payment') || description.contains('Overall Payment')) {
        enhancedDescription = 'Overall Payment';
      } else {
        enhancedDescription = 'Payment';
      }
    }
    
    final event = LoanPerformedEvent(
      name: name,
      serialNumber: serial,
      type: type,
      amount: amount,
      recordedDate: recordedDate,
      performedAt: today,  // Set to today's date at midnight for consistent filtering
      description: enhancedDescription,
      jewelleryName: jewelleryName ?? '-',
      dueAfter: dueAfter,
    );
    Hive.box<LoanPerformedEvent>('events').add(event);
  }

  // Export today's transactions (loans + deposits) to PDF using performed events
  Future<void> exportTodayReportToPDF() async {
    try {
      isLoading.value = true;

      final permissionGranted = await _requestStoragePermissions();
      if (!permissionGranted) {
        _showSnackbar('Error', 'Storage permission is required to save PDF.');
        return;
      }

      bool _sameDay(DateTime a, DateTime b) =>
          a.year == b.year && a.month == b.month && a.day == b.day;

      final today = DateTime.now();

      // Read events and filter by performedAt = today
      final eventsBox = Hive.box<LoanPerformedEvent>('events');
      final allEvents = eventsBox.values.toList();
      final todays = allEvents.where((e) => _sameDay(e.performedAt, today)).toList();

      // Map events to simple rows with display fields
      final rows = todays.map<Map<String, String>>((e) {
        final nep = NepaliDate.fromGregorian(e.recordedDate).format();
        String desc = e.description ?? e.type;
        
        // Process different types of transactions
        switch (e.type) {
          case 'repayment':
            // Keep the description as is if it's already set meaningfully
            if (desc.isEmpty || 
                desc == 'Payment received' || 
                desc == 'Overall payment received') {
              desc = 'Overall Payment';
            } else if (desc.contains('Interest Collection') || 
                      desc == 'Interest payment received') {
              desc = 'Interest Collection';
            } else if (desc.contains('Principal')) {
              desc = 'Principal Payment';
            } else {
              desc = 'Payment';
            }
            break;
          case 'disbursement':
            desc = 'Loan Disbursement';
            break;
          case 'topup':
            desc = 'Loan Top-up';
            break;
          // Add other cases as needed
        }
        return {
          'name': e.name,
          'serial': e.serialNumber.isEmpty ? '-' : e.serialNumber,
          'jewellery': (e.jewelleryName.isEmpty ? '-' : e.jewelleryName),
          'amount': e.amount.toStringAsFixed(0),
          'dateNep': nep,
          'due': e.dueAfter != null ? e.dueAfter!.toStringAsFixed(0) : '-',
          'desc': desc,
        };
      }).toList();

      // Compute counts for header
      final loanCount = todays.where((e) => e.type == 'disbursement' || e.type == 'repayment' || e.type == 'topup').length;
      final depositCount = todays.where((e) => e.type == 'deposit' || e.type == 'withdrawal').length;

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          build: (ctx) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Today\'s Transactions Report',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          )),
                      pw.Text(
                        'Date: ${today.toString().substring(0, 10)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Loans: $loanCount  |  Deposits: $depositCount',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),
            // Combined section (Loans + Deposits)
            pw.Text('Today\'s Actions',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (rows.isEmpty)
              pw.Text('No actions performed today.')
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _todayHeaderRow(),
                  pw.SizedBox(height: 6),
                  ...rows.map(_todayDataRow).toList(),
                ],
              ),
          ],
        ),
      );

      // Generate PDF bytes
      final pdfBytes = await pdf.save();
      
      // Get the file name with timestamp
      final fileName = 'today_transactions_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Ask user to select save location
      try {
        final String? outputPath = await getSavePath(
          suggestedName: fileName,
          acceptedTypeGroups: [
            XTypeGroup(
              label: 'PDF',
              extensions: ['pdf'],
              mimeTypes: ['application/pdf'],
            ),
          ],
        );
        
        if (outputPath != null) {
          final file = XFile.fromData(
            pdfBytes,
            mimeType: 'application/pdf',
            name: fileName,
          );
          
          // Save the file
          await file.saveTo(outputPath);
          
          // Open the PDF file
          await OpenFile.open(outputPath);
          
          _showSnackbar('Success', 'Today\'s report exported successfully');
        } else {
          _showSnackbar('Cancelled', 'Save operation was cancelled');
        }
      } catch (e) {
        print('Error saving file: $e');
        
        // Fallback to default location if file picker fails
        try {
          Directory? output;
          if (Platform.isAndroid) {
            output = Directory('/storage/emulated/0/Download');
            if (!await output.exists()) {
              output = await getExternalStorageDirectory();
              output ??= await getApplicationDocumentsDirectory();
            }
          } else {
            output = await getApplicationDocumentsDirectory();
          }
          
          final file = File('${output.path}/$fileName');
          await file.writeAsBytes(pdfBytes);
          await OpenFile.open(file.path);
          
          _showSnackbar('Success', 'Today\'s report saved to default location');
        } catch (e) {
          print('Error saving to default location: $e');
          _showSnackbar('Error', 'Failed to save today\'s report: $e');
        }
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to export today\'s report');
    } finally {
      isLoading.value = false;
    }
  }

  // Helpers to build header/data rows for today report
  pw.Widget _todayHeaderRow() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(children: [
        pw.Expanded(
            flex: 3,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text('Name', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)))),
        pw.Expanded(
            flex: 2,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text('Serial', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)))),
        pw.Expanded(
            flex: 3,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text('Jewellery', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)))),
        pw.Expanded(
            flex: 2,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text('Amount', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)))),
        pw.Expanded(
            flex: 2,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text('Due After', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)))),
        pw.Expanded(
            flex: 2,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text('Date (Nepali)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)))),
        pw.Expanded(
            flex: 5,
            child: pw.Text('Description', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
      ]),
    );
  }

  pw.Widget _todayDataRow(Map<String, String> e) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(children: [
        pw.Expanded(
            flex: 3,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text(e['name'] ?? '-', style: const pw.TextStyle(fontSize: 10)))),
        pw.Expanded(
            flex: 2,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text(e['serial'] ?? '-', style: const pw.TextStyle(fontSize: 10)))),
        pw.Expanded(
            flex: 3,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text(e['jewellery'] ?? '-', style: const pw.TextStyle(fontSize: 10)))),
        pw.Expanded(
            flex: 2,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text(e['amount'] ?? '-', style: const pw.TextStyle(fontSize: 10)))),
        pw.Expanded(
            flex: 2,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text(e['due'] ?? '-', style: const pw.TextStyle(fontSize: 10)))),
        pw.Expanded(
            flex: 2,
            child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 8),
                child: pw.Text(e['dateNep'] ?? '-', style: const pw.TextStyle(fontSize: 10)))),
        pw.Expanded(
            flex: 5,
            child: pw.Text(e['desc'] ?? '-', style: const pw.TextStyle(fontSize: 10))),
      ]),
    );
  }

  void loadLoans() {
    try {
      isLoading.value = true;
      loans.value = loanBox.values.toList();
      filteredLoans.value = loans;
      isSearchActive.value = false;
      hasExplicitSearch.value = false;

    

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
      _recordEvent(
        name: loan.name,
        serial: loan.serialNumber,
        type: 'disbursement',
        recordedDate: loan.date,
        amount: loan.amountGiven,
        jewelleryName: loan.jewelleryName,
        dueAfter: loan.dueAmount,
        description: 'Loan disbursed',
      );

      // Force UI refresh to update grouping
      refreshLoanCalculations();

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
  void addPartialRepayment(String serialNumber, double amount, DateTime date, {bool interestOnly = false, bool principalOnly = false}) {
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

      double adjustedAmount = amount;

      if (principalOnly) {
        // Clamp to remaining principal at effective date
        final remainingP = loan.remainingPrincipalAt(effectiveDate);
        if (adjustedAmount - remainingP > 0.005) {
          _showSnackbar(
            'Error',
            'Principal payment exceeds remaining principal (NPR ${remainingP.toStringAsFixed(2)})',
          );
          return;
        }
        if (adjustedAmount > remainingP) adjustedAmount = remainingP;
      } else {
        // Compute outstanding due as of the effective repayment date (no settlement enforcement)
        final outstanding = loan.outstandingDueAt(effectiveDate, forSettlement: false);

        // Do not allow overpayment; prevent negative balances
        if (adjustedAmount - outstanding > 0.005) {
          _showSnackbar(
            'Error',
            'Repayment exceeds outstanding due (NPR ${outstanding.toStringAsFixed(2)})',
          );
          return;
        }

        // If amount is slightly more due to rounding, clamp to outstanding
        if (adjustedAmount > outstanding) adjustedAmount = outstanding;

        // For interest-only collections: clamp to interest component at effective date
        // Interest component honors overdue compounding: interest = outstanding - remaining principal
        if (interestOnly) {
          final dueAt = loan.outstandingDueAt(effectiveDate, forSettlement: false);
          final rpAt = loan.remainingPrincipalAt(effectiveDate);
          final interestAtDate = (dueAt - rpAt).clamp(0.0, double.infinity);
          if (adjustedAmount > interestAtDate) {
            adjustedAmount = interestAtDate;
          }
        }
      }

      // Save the loan to ensure all changes are persisted
      loan.addPartialRepayment(
        adjustedAmount,
        effectiveDate,
        interestOnly: interestOnly,
        principalOnly: principalOnly,
      );
      
      // Save the loan to Hive
      loan.save();
      
      // Force a refresh of the loan data from the database
      final refreshedLoan = loanBox.get(loan.key);
      if (refreshedLoan != null) {
        loans[loanIndex] = refreshedLoan;
        // Update filtered loans to trigger UI refresh
        filteredLoans[filteredLoans.indexWhere((l) => l.serialNumber == refreshedLoan.serialNumber)] = refreshedLoan;
      } else {
        // Fallback to the updated loan if refresh fails
        loans[loanIndex] = loan;
        filteredLoans[filteredLoans.indexWhere((l) => l.serialNumber == loan.serialNumber)] = loan;
      }
      
      // Force a UI update by creating a new list
      filteredLoans.refresh();
      loans.refresh();
      
      // Notify all listeners
      update(['loan_summary']); // Specific ID for loan summary updates
      String paymentType;
      if (interestOnly) {
        paymentType = 'Interest';
      } else if (principalOnly) {
        paymentType = 'Principal';
      } else if (adjustedAmount >= (loan.dueAmount * 0.9)) { // If payment is 90% or more of due, consider it full payment
        paymentType = 'Full Payment';
      } else {
        paymentType = 'Partial Payment';
      }

      _recordEvent(
        name: loan.name,
        serial: loan.serialNumber,
        type: 'repayment',
        recordedDate: effectiveDate,
        amount: adjustedAmount,
        description: paymentType == 'Interest' ? 'Interest Collection' : '$paymentType: NPR ${adjustedAmount.toStringAsFixed(2)}',
        jewelleryName: loan.jewelleryName,
        dueAfter: loan.outstandingDueAt(effectiveDate, forSettlement: false),
        isInterestOnly: paymentType == 'Interest',
      );
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

      // For overdue loans, don't enforce the 30-day minimum interest rule
      final isOverdue = loan.isOverdue;
      final outstanding = loan.outstandingDueAt(
        effectiveDate, 
        forSettlement: !isOverdue, // false for overdue loans, true for non-overdue
      );

      // Do not allow overpayment; prevent negative balances
      if (amount - outstanding > 0.005) {
        _showSnackbar(
          'Error',
          'Repayment exceeds outstanding due (NPR ${outstanding.toStringAsFixed(2)})',
        );
        return;
      }

      final adjustedAmount = amount > outstanding ? outstanding : amount;

      // Process the payment
      loan.addPartialRepayment(adjustedAmount, effectiveDate);
      
      // Save the loan to Hive
      loan.save();
      
      // Force a refresh of the loan data from the database
      final refreshedLoan = loanBox.get(loan.key);
      if (refreshedLoan != null) {
        loans[loanIndex] = refreshedLoan;
        // Update filtered loans to trigger UI refresh
        final filteredIndex = filteredLoans.indexWhere((l) => l.serialNumber == refreshedLoan.serialNumber);
        if (filteredIndex != -1) {
          filteredLoans[filteredIndex] = refreshedLoan;
        }
      } else {
        // Fallback to the updated loan if refresh fails
        loans[loanIndex] = loan;
        final filteredIndex = filteredLoans.indexWhere((l) => l.serialNumber == loan.serialNumber);
        if (filteredIndex != -1) {
          filteredLoans[filteredIndex] = loan;
        }
      }
      
      // Record the payment event
      _recordEvent(
        name: loan.name,
        serial: loan.serialNumber,
        type: 'repayment',
        recordedDate: effectiveDate,
        amount: adjustedAmount,
        description: 'Overall Payment: NPR ${adjustedAmount.toStringAsFixed(2)}',
        jewelleryName: loan.jewelleryName,
        dueAfter: loan.outstandingDueAt(effectiveDate, forSettlement: false),
        isInterestOnly: false,
      );
      
      // Force a UI update by refreshing the reactive lists
      filteredLoans.refresh();
      loans.refresh();
      
      // Notify all listeners, especially the loan summary
      update(['loan_summary']);
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
      _recordEvent(
        name: loan.name,
        serial: loan.serialNumber,
        type: 'topup',
        recordedDate: effectiveDate,
        amount: amount,
        jewelleryName: loan.jewelleryName,
        dueAfter: loan.dueAmount,
        description: 'Top-up added',
      );
      loan.save();
      loans[loanIndex] = loan;
      filteredLoans.value = loans;
      refreshLoanCalculations();
    } catch (e) {
      print('Error adding top up: $e');
      _showSnackbar('Error', 'Failed to add top-up');
    }
  }

  InterestRateChange? changeInterestRate(
    String serialNumber,
    double newRate,
    DateTime effectiveDate,
  ) {
    try {
      if (newRate <= 0) {
        _showSnackbar('Error', 'Interest rate must be positive');
        return null;
      }

      final loanIndex = loans.indexWhere(
        (loan) => loan.serialNumber == serialNumber,
      );
      if (loanIndex == -1) {
        _showSnackbar('Error', 'Loan not found');
        return null;
      }

      final loan = loans[loanIndex];
      if ((loan.interestRate - newRate).abs() < 0.000001) {
        _showSnackbar('No Change', 'The new rate is the same as the current rate');
        return null;
      }

      final effective = effectiveDate.isBefore(loan.date)
          ? loan.date
          : effectiveDate;
      final change = loan.changeInterestRate(newRate, effective);
      loan.save();

      loans[loanIndex] = loan;
      final filteredIndex = filteredLoans.indexWhere(
        (l) => l.serialNumber == serialNumber,
      );
      if (filteredIndex != -1) {
        filteredLoans[filteredIndex] = loan;
      }

      loans.refresh();
      filteredLoans.refresh();
      refreshLoanCalculations();
      update(['loan_summary']);

      _recordEvent(
        name: loan.name,
        serial: loan.serialNumber,
        type: 'rate_change',
        recordedDate: effective,
        amount: change.adjustmentAmount.abs(),
        jewelleryName: loan.jewelleryName,
        dueAfter: change.recalculatedDue,
        description:
            '${change.isIncrease ? 'Interest Rate Increased' : 'Interest Rate Decreased'}: '
            '${change.previousRate.toStringAsFixed(2)}% to ${change.newRate.toStringAsFixed(2)}%',
      );

      _showSnackbar('Success', 'Interest rate updated successfully');
      return change;
    } catch (e) {
      print('Error changing interest rate: $e');
      _showSnackbar('Error', 'Failed to update interest rate');
      return null;
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
      // Use remainingPrincipal instead of amountGiven to account for principal repayments
      return loans.fold(0.0, (sum, loan) => sum + loan.remainingPrincipal);
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

  double getTotalPrincipalDue() {
    try {
      return loans.fold(0.0, (sum, loan) => sum + loan.remainingPrincipalAt(DateTime.now()));
    } catch (e) {
      print('Error calculating total principal due: $e');
      return 0.0;
    }
  }

  double getTotalInterestDue() {
    try {
      return loans.fold(0.0, (sum, loan) => sum + (loan.dueAmount - loan.remainingPrincipalAt(DateTime.now())));
    } catch (e) {
      print('Error calculating total interest due: $e');
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

  // Get list of all overdue loans
  List<Loan> getOverdueLoans() {
    try {
      return loans.where((loan) => loan.isOverdue).toList();
    } catch (e) {
      print('Error getting overdue loans: $e');
      return [];
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
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                margin: const pw.EdgeInsets.only(top: 24, bottom: 24),
                padding: const pw.EdgeInsets.all(16),
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
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Total Amount Given',
                            getTotalLoansAmount().toStringAsFixed(0),
                            PdfColors.blue,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Total Amount Received',
                            getTotalReceivedAmount().toStringAsFixed(0),
                            PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Total Due Amount',
                            getTotalDueAmount().toStringAsFixed(0),
                            PdfColors.red,
                          ),
                        ),
                        pw.SizedBox(width: 12),
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

      // Generate PDF bytes
      final pdfBytes = await pdf.save();
      
      // Get the file name with timestamp
      final fileName = 'loan_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Ask user to select save location
      try {
        final String? outputPath = await getSavePath(
          suggestedName: fileName,
          acceptedTypeGroups: [
            XTypeGroup(
              label: 'PDF',
              extensions: ['pdf'],
              mimeTypes: ['application/pdf'],
            ),
          ],
        );
        
        if (outputPath != null) {
          final file = XFile.fromData(
            pdfBytes,
            mimeType: 'application/pdf',
            name: fileName,
          );
          
          // Save the file
          await file.saveTo(outputPath);
          
          // Open the PDF file
          await OpenFile.open(outputPath);
          
          _showSnackbar('Success', 'PDF exported successfully');
        } else {
          _showSnackbar('Cancelled', 'Save operation was cancelled');
        }
      } catch (e) {
        print('Error saving file: $e');
        
        // Fallback to default location if file picker fails
        try {
          Directory? output;
          if (Platform.isAndroid) {
            output = Directory('/storage/emulated/0/Download');
            if (!await output.exists()) {
              output = await getExternalStorageDirectory();
              output ??= await getApplicationDocumentsDirectory();
            }
          } else {
            output = await getApplicationDocumentsDirectory();
          }
          
          final file = File('${output.path}/$fileName');
          await file.writeAsBytes(pdfBytes);
          await OpenFile.open(file.path);
          
          _showSnackbar('Success', 'PDF saved to default location');
        } catch (e) {
          print('Error saving to default location: $e');
          _showSnackbar('Error', 'Failed to save PDF: $e');
        }
      }
    } catch (e) {
      print('Error exporting PDF: $e');
      _showSnackbar('Error', 'Failed to export PDF: $e');
    } finally {
      isLoading.value = false;
    }
  }

  pw.Widget _buildSummaryBox(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
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
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 17,
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
          margin: const pw.EdgeInsets.only(bottom: 24),
          padding: const pw.EdgeInsets.all(16),
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
                      customerLoans
                          .fold(0.0, (sum, loan) => sum + loan.amountGiven)
                          .toStringAsFixed(0),
                    ),
                  ),
                  pw.Expanded(
                    child: _buildCustomerSummaryItem(
                      'Total Received',
                      customerLoans
                          .fold(0.0, (sum, loan) => sum + loan.amountReceived)
                          .toStringAsFixed(0),
                    ),
                  ),
                  pw.Expanded(
                    child: _buildCustomerSummaryItem(
                      'Total Due',
                      totalDue.toStringAsFixed(0),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 15),

              // Individual Loans Table
              pw.Text(
                'Individual Loans:',
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              // Table Header
              pw.Container(
                padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  .asMap()
                  .entries
                  .map(
                    (entry) {
                      final idx = entry.key;
                      final loan = entry.value;
                      final rowBg = loan.isOverdue
                          ? PdfColors.red50
                          : (idx % 2 == 0 ? PdfColors.white : PdfColors.grey100);
                      return pw.Container(
                        margin: pw.EdgeInsets.only(top: 6),
                        padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: pw.BoxDecoration(
                          color: rowBg,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(flex: 2, child: pw.Text(loan.serialNumber)),
                            pw.Expanded(flex: 3, child: pw.Text(loan.jewelleryName)),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(loan.amountGiven.toStringAsFixed(0)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(loan.amountReceived.toStringAsFixed(0)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(loan.dueAmount.toStringAsFixed(0)),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                loan.isOverdue ? 'Overdue' : 'Active',
                                style: pw.TextStyle(
                                  color: loan.isOverdue ? PdfColors.red : PdfColors.green,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                margin: const pw.EdgeInsets.only(top: 24, bottom: 24),
                padding: const pw.EdgeInsets.all(16),
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
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Total Amount Given',
                            'NPR ${customerLoans.fold(0.0, (sum, loan) => sum + loan.amountGiven).toStringAsFixed(2)}',
                            PdfColors.blue,
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Expanded(
                          child: _buildSummaryBox(
                            'Total Amount Received',
                            'NPR ${customerLoans.fold(0.0, (sum, loan) => sum + loan.amountReceived).toStringAsFixed(2)}',
                            PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
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
