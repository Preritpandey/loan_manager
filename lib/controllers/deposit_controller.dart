import 'dart:io';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:list/models/deposit.dart';
import 'package:list/utils/nepali_date_utils.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class DepositController extends GetxController {
  final Box<DepositModel> depositBox = Hive.box<DepositModel>('deposits');
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
      deposits.value = depositBox.values.toList();
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
      final prior = model.currentBalance;
      double next = prior;
      if (type == 'Deposit') {
        next = prior + amount;
      } else if (type == 'Withdrawal') {
        if (amount > prior) {
          _snack(
            'Error',
            'Withdrawal exceeds current balance (NPR ${prior.toStringAsFixed(2)})',
          );
          return;
        }
        next = prior - amount;
      } else {
        _snack('Error', 'Invalid transaction type');
        return;
      }

      final txn = DepositTransaction(
        type: type,
        amount: amount,
        dateNepali: nepaliDate,
        description: description,
        balanceAfter: next,
        dateAD: NepaliDate.parse(nepaliDate)?.toGregorian(),
      );

      model.transactions = List<DepositTransaction>.from(model.transactions)
        ..add(txn);
      model.save();
      deposits[idx] = model; // trigger update
      filtered.value = deposits;
      _snack('Success', '$type recorded');
    } catch (e) {
      _snack('Error', 'Failed to add transaction');
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

  void _snack(String title, String message) {
    try {
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
      });
    } catch (_) {}
  }
}
