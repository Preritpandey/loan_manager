import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_detail_operations_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/loan_status_header_widget.dart';
import 'package:list/widgets/personal_info_card_widget.dart';
import 'package:list/widgets/loan_info_card_widget.dart';
import 'package:list/widgets/jewellery_info_card_widget.dart';
import 'package:list/widgets/financial_summary_card_widget.dart';
import 'package:list/widgets/description_card_widget.dart';
import 'package:list/widgets/payment_options_card_widget.dart';
import 'package:list/widgets/loan_statement_tiles_widget.dart';
import 'package:list/widgets/customer_summary_card_widget.dart';
import 'package:list/widgets/delete_loan_card_widget.dart';
import 'package:flutter/services.dart';
import 'package:list/controllers/bank_loan_controller.dart';

class LoanDetailPage extends StatefulWidget {
  final Loan loan;

  const LoanDetailPage({super.key, required this.loan});

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  late final LoanDetailOperationsController operationsController;

  late final BankLoanController bankLoanController;

  @override
  void initState() {
    super.initState();
    bankLoanController = Get.find<BankLoanController>();
    operationsController = Get.put(LoanDetailOperationsController());
    operationsController.initializeLoan(widget.loan);
  }

  @override
  void dispose() {
    Get.delete<LoanDetailOperationsController>();
    // Do not delete BankLoanController here; it's shared across the app.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;
    final maxWidth = isDesktop ? 1000.0 : double.infinity;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: GetBuilder<LoanDetailOperationsController>(
          builder: (ops) {
            final loan = ops.loan;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Serial: ${loan.serialNumber}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: Color.fromARGB(255, 204, 21, 27),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minHeight:
                  MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top,
            ),
            child: Column(
              children: [
                GetBuilder<LoanDetailOperationsController>(
                  builder: (ops) {
                    final loan = ops.loan;
                    return Column(
                      children: [
                        // Add to Bank Button - Wrapped in Obx and referencing Rx to react to changes
                        Obx(() {
                          // Access RxList bankLoans to ensure Obx has an observable dependency
                          final isInBank = bankLoanController.bankLoans.any(
                            (b) => b.loanId == loan.loanId,
                          );
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: isInBank
                                  ? null
                                  : () async {
                                      final success = await bankLoanController
                                          .addLoanToBank(loan);
                                      if (success) {
                                        Get.snackbar(
                                          'Success',
                                          'Loan added to bank collection',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Colors.green,
                                          colorText: Colors.white,
                                        );
                                      } else {
                                        Get.snackbar(
                                          'Error',
                                          'Failed to add loan to bank',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Colors.red,
                                          colorText: Colors.white,
                                        );
                                      }
                                    },
                              icon: Icon(
                                isInBank
                                    ? Icons.account_balance
                                    : Icons.account_balance_wallet,
                              ),
                              label: Text(
                                isInBank ? 'Added to Bank' : 'Add to Bank',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isInBank
                                    ? Colors.grey
                                    : Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          );
                        }),

                        // Status Header
                        LoanStatusHeader(loan: loan),
                        const SizedBox(height: 8),
                        _DurationOverrideBar(controller: operationsController),

                        if (isDesktop)
                          _buildDesktopLayout(loan)
                        else
                          _buildMobileLayout(loan),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Loan loan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              PersonalInfoCard(loan: loan),
              LoanInfoCard(loan: loan),
              JewelleryInfoCard(loan: loan),
              DescriptionCard(loan: loan),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              FinancialSummaryCard(loan: loan),
              const SizedBox(height: 8),
              LoanStatementTiles(loan: loan),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              PaymentOptionsCard(loan: loan),
              DeleteLoanCard(
                loan: loan,
                onDelete: () =>
                    operationsController.showDeleteConfirmationDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Loan loan) {
    return Column(
      children: [
        PersonalInfoCard(loan: loan),
        LoanInfoCard(loan: loan),
        JewelleryInfoCard(loan: loan),
        FinancialSummaryCard(loan: loan),
        const SizedBox(height: 8),
        LoanStatementTiles(loan: loan),
        const SizedBox(height: 8),
        DescriptionCard(loan: loan),
        CustomerSummaryCard(loan: loan),
        const SizedBox(height: 8),
        PaymentOptionsCard(loan: loan),
        DeleteLoanCard(
          loan: loan,
          onDelete: () => operationsController.showDeleteConfirmationDialog(),
        ),
      ],
    );
  }
}

class _DurationOverrideBar extends StatelessWidget {
  final LoanDetailOperationsController controller;
  const _DurationOverrideBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoanDetailOperationsController>(
      builder: (ops) {
        final active = ops.isDurationOverrideActive;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? Colors.amber[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (active ? Colors.amber[200] : Colors.blue[200])!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                active ? Icons.timer : Icons.calculate,
                color: active ? Colors.amber[800] : Colors.blue[800],
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: active
                    ? Text(
                        'Duration override active: ${ops.overrideDays} day(s). Totals reflect this.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[900],
                        ),
                      )
                    : Text(
                        'Default: Using daily interest since start date. Enter a duration to override.',
                        style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                      ),
              ),
              if (!active) ...[
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: controller.durationOverrideInputController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Duration (days)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final v =
                        int.tryParse(
                          controller.durationOverrideInputController.text
                              .trim(),
                        ) ??
                        0;
                    if (v > 0) {
                      controller.activateDurationOverride(v);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: controller.clearDurationOverride,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber[900],
                    side: BorderSide(color: Colors.amber[300]!),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
