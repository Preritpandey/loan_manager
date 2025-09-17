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

class LoanDetailPage extends StatefulWidget {
  final Loan loan;

  const LoanDetailPage({super.key, required this.loan});

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  late final LoanDetailOperationsController operationsController;

  @override
  void initState() {
    super.initState();
    operationsController = Get.put(LoanDetailOperationsController());
    operationsController.initializeLoan(widget.loan);
  }

  @override
  void dispose() {
    Get.delete<LoanDetailOperationsController>();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.loan.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Serial: ${widget.loan.serialNumber}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 204, 21, 27),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: GetBuilder<LoanDetailOperationsController>(
              builder: (ops) {
                final loan = ops.loan;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Header
                    LoanStatusHeader(loan: loan),

                    if (isDesktop)
                      _buildDesktopLayout(loan)
                    else
                      _buildMobileLayout(loan),
                  ],
                );
              },
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
              if (loan.description.isNotEmpty) DescriptionCard(loan: loan),
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
              CustomerSummaryCard(loan: loan),
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
        if (loan.description.isNotEmpty) DescriptionCard(loan: loan),
        CustomerSummaryCard(loan: loan),
        PaymentOptionsCard(loan: loan),
        DeleteLoanCard(
          loan: loan,
          onDelete: () => operationsController.showDeleteConfirmationDialog(),
        ),
      ],
    );
  }
}
