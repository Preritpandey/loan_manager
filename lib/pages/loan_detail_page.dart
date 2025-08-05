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
import 'package:list/widgets/update_received_amount_card_widget.dart';
import 'package:list/widgets/custom_days_calculation_card_widget.dart';
import 'package:list/widgets/additional_loan_card_widget.dart';
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
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Header
                LoanStatusHeader(loan: widget.loan),

                if (isDesktop) _buildDesktopLayout() else _buildMobileLayout(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              PersonalInfoCard(loan: widget.loan),
              LoanInfoCard(loan: widget.loan),
              JewelleryInfoCard(loan: widget.loan),
              if (widget.loan.description.isNotEmpty)
                DescriptionCard(loan: widget.loan),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              FinancialSummaryCard(loan: widget.loan),
              CustomerSummaryCard(loan: widget.loan),
              Obx(
                () => UpdateReceivedAmountCard(
                  loan: widget.loan,
                  controller: operationsController.receivedAmountController,
                  isProcessing: operationsController.isProcessingAction.value,
                  onUpdate: () => operationsController.updateReceivedAmount(),
                ),
              ),
              CustomDaysCalculationCard(loan: widget.loan),
              AdditionalLoanCard(loan: widget.loan),
              DeleteLoanCard(
                loan: widget.loan,
                onDelete: () =>
                    operationsController.showDeleteConfirmationDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        PersonalInfoCard(loan: widget.loan),
        LoanInfoCard(loan: widget.loan),
        JewelleryInfoCard(loan: widget.loan),
        FinancialSummaryCard(loan: widget.loan),
        if (widget.loan.description.isNotEmpty)
          DescriptionCard(loan: widget.loan),
        CustomerSummaryCard(loan: widget.loan),
        Obx(
          () => UpdateReceivedAmountCard(
            loan: widget.loan,
            controller: operationsController.receivedAmountController,
            isProcessing: operationsController.isProcessingAction.value,
            onUpdate: () => operationsController.updateReceivedAmount(),
          ),
        ),
        CustomDaysCalculationCard(loan: widget.loan),
        AdditionalLoanCard(loan: widget.loan),
        DeleteLoanCard(
          loan: widget.loan,
          onDelete: () => operationsController.showDeleteConfirmationDialog(),
        ),
      ],
    );
  }
}
