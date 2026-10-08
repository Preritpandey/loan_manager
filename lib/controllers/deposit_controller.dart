import 'dart:io';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:list/models/deposit.dart';
import 'package:list/services/cash_deposit_interest_service.dart';
import 'package:list/utils/nepali_date_utils.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:list/models/loan_event.dart';

class DepositController extends GetxController {
  final Box<DepositModel> depositBox = Hive.box<DepositModel>('deposits');
  final CashDepositInterestService interestService =
      CashDepositInterestService();
  final deposits = <DepositModel>[].obs;
  final filtered = <DepositModel>[].obs;
  final isLoading = false.obs;
  final isSearchActive = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() {
    try {
      isLoading.value = true;
      final loaded = depositBox.values.toList();
      for (final deposit in loaded) {
        final previousTransactionCount = deposit.transactions.length;
        deposit.migrateLegacyTransactionsToLots();
        interestService.processMaturedDeposits(deposit);
        if (deposit.transactions.length != previousTransactionCount ||
            deposit.lots.isNotEmpty) {
          deposit.save();
        }
      }
      deposits.value = loaded;
      filtered.value = deposits;
      isSearchActive.value = false;
    } catch (e) {
      _snack('Error', 'Failed to load deposits');
    } finally {
      isLoading.value = false;
    }
  }

  void addDepositAccount(DepositModel model) {
    try {
      // check duplicates by name+phone
      if (deposits.any(
        (d) =>
            d.name.trim().toLowerCase() == model.name.trim().toLowerCase() &&
            d.phone == model.phone,
      )) {
        _snack('Error', 'A deposit account for this customer already exists');
        return;
      }
      depositBox.add(model);
      deposits.add(model);
      filtered.value = deposits;
      _snack('Success', 'Deposit account created');
    } catch (e) {
      _snack('Error', 'Failed to create deposit account');
    }
  }

  void addTransaction({
    required String depositId,
    required String type, // 'Deposit' or 'Withdrawal'
    required double amount,
    required String nepaliDate,
    String? description,
  }) {
    try {
      final idx = deposits.indexWhere((d) => d.depositId == depositId);
      if (idx == -1) {
        _snack('Error', 'Deposit account not found');
        return;
      }
      final model = deposits[idx];
      if (type == 'Deposit') {
        model.addDepositLot(
          amount: amount,
          nepaliDateString: nepaliDate,
          rate: model.interestRate,
          description: description,
        );
      } else if (type == 'Withdrawal') {
        if (amount > model.totalPrincipal) {
          _snack(
            'Error',
            'Withdrawal exceeds principal (NPR ${model.totalPrincipal.toStringAsFixed(2)})',
          );
          return;
        }
        model.withdrawPrincipal(
          amount: amount,
          nepaliDateString: nepaliDate,
          description: description,
        );
      } else {
        _snack('Error', 'Invalid transaction type');
        return;
      }
      model.save();
      // Record performed event for strict 'performed today' logic
      try {
        final box = Hive.box<LoanPerformedEvent>('events');
        final ev = LoanPerformedEvent(
          name: model.name,
          serialNumber: '',
          type: type.toLowerCase() == 'withdrawal' ? 'withdrawal' : 'deposit',
          amount: amount,
          recordedDate:
              NepaliDate.parse(nepaliDate)?.toGregorian() ?? DateTime.now(),
          description: description ?? type,
        );
        box.add(ev);
      } catch (_) {}
      deposits[idx] = model; // trigger update
      filtered.value = deposits;
      _snack('Success', '$type recorded');
    } catch (e) {
      _snack('Error', 'Failed to add transaction');
    }
  }

  void addDepositLot({
    required String depositId,
    required double amount,
    required String nepaliDate,
    required double interestRate,
    String? description,
  }) {
    try {
      final idx = deposits.indexWhere((d) => d.depositId == depositId);
      if (idx == -1) {
        _snack('Error', 'Deposit account not found');
        return;
      }
      final model = deposits[idx];
      model.addDepositLot(
        amount: amount,
        nepaliDateString: nepaliDate,
        rate: interestRate,
        description: description,
      );
      model.save();
      deposits[idx] = model;
      filtered.value = deposits;
      _recordEvent(model, 'deposit', amount, nepaliDate, description);
      _snack('Success', 'Deposit recorded');
    } catch (e) {
      _snack('Error', 'Failed to add deposit');
    }
  }

  List<DepositWithdrawalAllocation> previewPrincipalWithdrawal({
    required String depositId,
    required double amount,
  }) {
    final model = getById(depositId);
    if (model == null) return [];
    return model.previewPrincipalWithdrawal(amount);
  }

  void withdraw({
    required String depositId,
    required double amount,
    required String nepaliDate,
    required String source,
    String? description,
  }) {
    try {
      final idx = deposits.indexWhere((d) => d.depositId == depositId);
      if (idx == -1) {
        _snack('Error', 'Deposit account not found');
        return;
      }
      final model = deposits[idx];
      if (source == 'principal') {
        model.withdrawPrincipal(
          amount: amount,
          nepaliDateString: nepaliDate,
          description: description,
        );
      } else {
        model.withdrawInterest(
          amount: amount,
          nepaliDateString: nepaliDate,
          description: description,
        );
      }
      model.save();
      deposits[idx] = model;
      filtered.value = deposits;
      _recordEvent(model, 'withdrawal', amount, nepaliDate, description);
      _snack('Success', 'Withdrawal recorded');
    } catch (e) {
      _snack('Error', e.toString().replaceFirst('Invalid argument(s): ', ''));
    }
  }

  void processInterest(String depositId) {
    try {
      final idx = deposits.indexWhere((d) => d.depositId == depositId);
      if (idx == -1) {
        _snack('Error', 'Deposit account not found');
        return;
      }
      final model = deposits[idx];
      final generated = interestService.processMaturedDeposits(model);
      model.save();
      deposits[idx] = model;
      filtered.value = deposits;
      _snack(
        generated.isEmpty ? 'Info' : 'Success',
        generated.isEmpty
            ? 'No eligible interest to apply'
            : '${generated.length} interest transaction(s) applied',
      );
    } catch (e) {
      _snack('Error', 'Failed to process interest');
    }
  }

  void search(String query) {
    final q = query.trim();
    if (q.isEmpty) {
      filtered.value = deposits;
      isSearchActive.value = false;
      return;
    }
    isSearchActive.value = true;
    filtered.value = deposits
        .where((d) => d.name.toLowerCase().contains(q.toLowerCase()))
        .toList();
  }

  void clearSearch() {
    filtered.value = deposits;
    isSearchActive.value = false;
  }

  DepositModel? getById(String depositId) {
    final idx = deposits.indexWhere((d) => d.depositId == depositId);
    return idx == -1 ? null : deposits[idx];
  }

  void _recordEvent(
    DepositModel model,
    String type,
    double amount,
    String nepaliDate,
    String? description,
  ) {
    try {
      final box = Hive.box<LoanPerformedEvent>('events');
      box.add(
        LoanPerformedEvent(
          name: model.name,
          serialNumber: '',
          type: type,
          amount: amount,
          recordedDate: NepaliDate.parse(nepaliDate)?.toGregorian() ??
              DateTime.now(),
          description: description ?? type,
        ),
      );
    } catch (_) {}
  }

  // Permissions (reuse approach from loan controller)
  Future<bool> _requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isGranted) return true;
        final manage = await Permission.manageExternalStorage.request();
        if (manage.isGranted) return true;
        final results = await [
          Permission.storage,
          if (Platform.isAndroid) Permission.photos,
        ].request();
        return results.values.any((s) => s.isGranted);
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> exportCustomerDepositToPDF(String depositId) async {
    try {
      final model = getById(depositId);
      if (model == null) {
        _snack('Error', 'Deposit account not found');
        return;
      }

      bool permissionGranted = await _requestStoragePermissions();
      if (!permissionGranted) {
        _snack('Error', 'Storage permission required to save PDF');
        return;
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
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
                        'Cash Deposit Statement',
                        style: pw.TextStyle(
                          fontSize: 22,
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
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Text(
                      'Balance: NPR ${model.currentBalance.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Customer details
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
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
                  pw.SizedBox(height: 6),
                  pw.Text('Name: ${model.name}'),
                  pw.Text('Phone: ${model.phone}'),
                  pw.Text('Address: ${model.address}'),
                  pw.Text('Interest Rate (Yearly): ${model.interestRate}%'),
                  if (model.description != null &&
                      model.description!.isNotEmpty)
                    pw.Text('Description: ${model.description}'),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Transactions table header
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Date (Nepali)',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Type',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Amount',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Balance After',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Description',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Transactions
            ...model.transactionsSortedDesc.map(
              (t) => pw.Container(
                padding: const pw.EdgeInsets.all(8),
                margin: const pw.EdgeInsets.only(top: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text(t.dateNepali)),
                    pw.Expanded(flex: 2, child: pw.Text(t.type)),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('NPR ${t.amount.toStringAsFixed(2)}'),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'NPR ${t.balanceAfter.toStringAsFixed(2)}',
                      ),
                    ),
                    pw.Expanded(flex: 3, child: pw.Text(t.description ?? '-')),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

      Directory? output;
      try {
        if (Platform.isAndroid) {
          output = Directory('/storage/emulated/0/Download');
          if (!await output.exists()) {
            output = await getExternalStorageDirectory();
            output ??= await getApplicationDocumentsDirectory();
          }
        } else {
          output = await getApplicationDocumentsDirectory();
        }
      } catch (_) {
        output = await getTemporaryDirectory();
      }

      final file = File(
        '${output.path}/cash_deposit_${model.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
      _snack('Success', 'PDF exported successfully');
    } catch (e) {
      _snack('Error', 'Failed to export PDF');
    }
  }

  Future<void> exportAllDepositsToPDF() async {
    try {
      if (deposits.isEmpty) {
        _snack('Info', 'No deposits to export');
        return;
      }

      bool permissionGranted = await _requestStoragePermissions();
      if (!permissionGranted) {
        _snack('Error', 'Storage permission required to save PDF');
        return;
      }

      final all = List<DepositModel>.from(deposits)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      final totalBalance = all.fold<double>(
        0.0,
        (sum, d) => sum + d.currentBalance,
      );

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
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
                        'All Cash Deposits Report',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Generated on: ${DateTime.now().toString().substring(0, 19)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue,
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Text(
                          'Total Balance: NPR ${totalBalance.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Total Customers: ${all.length}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // For each customer
            ...all.expand((model) {
              return [
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            model.name,
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.green,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(6),
                              ),
                            ),
                            child: pw.Text(
                              'Balance: NPR ${model.currentBalance.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Phone: ${model.phone}'),
                      pw.Text('Address: ${model.address}'),
                      pw.Text('Interest Rate (Yearly): ${model.interestRate}%'),
                      if (model.description != null &&
                          model.description!.isNotEmpty)
                        pw.Text('Description: ${model.description}'),
                      pw.SizedBox(height: 8),

                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                'Date (Nepali)',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                'Type',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                'Amount',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 2,
                              child: pw.Text(
                                'Balance After',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Expanded(
                              flex: 3,
                              child: pw.Text(
                                'Description',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      ...model.transactionsSortedDesc.map(
                        (t) => pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          margin: const pw.EdgeInsets.only(top: 2),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(t.dateNepali),
                              ),
                              pw.Expanded(flex: 2, child: pw.Text(t.type)),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  'NPR ${t.amount.toStringAsFixed(2)}',
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  'NPR ${t.balanceAfter.toStringAsFixed(2)}',
                                ),
                              ),
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(t.description ?? '-'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            }).toList(),
          ],
        ),
      );

      Directory? output;
      try {
        if (Platform.isAndroid) {
          output = Directory('/storage/emulated/0/Download');
          if (!await output.exists()) {
            output = await getExternalStorageDirectory();
            output ??= await getApplicationDocumentsDirectory();
          }
        } else {
          output = await getApplicationDocumentsDirectory();
        }
      } catch (_) {
        output = await getTemporaryDirectory();
      }

      final file = File(
        '${output.path}/cash_deposits_all_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
      _snack('Success', 'All deposits PDF exported successfully');
    } catch (e) {
      _snack('Error', 'Failed to export all deposits');
    }
  }

  Future<void> deleteDeposit(String depositId) async {
    try {
      final deposit = deposits.firstWhere((d) => d.depositId == depositId);
      await deposit.delete();
      deposits.removeWhere((d) => d.depositId == depositId);
      filtered.value = List<DepositModel>.from(deposits);
      _snack('Success', 'Deposit account deleted');
    } catch (e) {
      _snack('Error', 'Failed to delete deposit account');
    }
  }

  void _snack(String title, String message) {
    try {
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
      });
    } catch (_) {}
  }
}
