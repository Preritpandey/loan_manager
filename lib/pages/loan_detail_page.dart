import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/add_additional_loan_page.dart';
import 'package:list/widgets/info_row_widget.dart';
import 'package:list/widgets/info_card_widget.dart';
import 'package:list/widgets/status_badge_widget.dart';
import 'package:list/widgets/loan_status_header_widget.dart';
import 'package:list/widgets/personal_info_card_widget.dart';
import 'package:list/widgets/loan_info_card_widget.dart';
import 'package:list/widgets/jewellery_info_card_widget.dart';
import 'package:list/widgets/financial_summary_card_widget.dart';
import 'package:list/widgets/description_card_widget.dart';
import 'package:list/widgets/update_received_amount_card_widget.dart';
import 'package:list/widgets/partial_repayment_card_widget.dart';
import 'package:list/widgets/additional_loan_card_widget.dart';
import 'package:list/widgets/customer_summary_card_widget.dart';
import 'package:list/widgets/delete_loan_card_widget.dart';
import 'dart:async'; // Added for Timer

class LoanDetailPage extends StatefulWidget {
  final Loan loan;

  const LoanDetailPage({super.key, required this.loan});

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  final TextEditingController _receivedAmountController =
      TextEditingController();
  final TextEditingController _partialRepaymentAmountController =
      TextEditingController();
  final LoanController _loanController = Get.find<LoanController>();
  Timer? _updateTimer;
  bool _isProcessingAction = false; // Prevent multiple simultaneous actions

  @override
  void initState() {
    super.initState();
    _receivedAmountController.text = widget.loan.amountReceived.toString();

    // Set up timer for real-time updates (updates every minute)
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // Force rebuild to update calculations
        });
      }
    });
  }

  @override
  void dispose() {
    _receivedAmountController.dispose();
    _partialRepaymentAmountController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _updateReceivedAmount() {
    if (_isProcessingAction) return; // Prevent multiple simultaneous actions

    final newAmount = double.tryParse(_receivedAmountController.text) ?? 0.0;

    if (newAmount < 0) {
      _showSnackbar(
        'Error',
        'Received amount cannot be negative',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isProcessingAction = true;
    });

    try {
      _loanController.updateReceivedAmountBySerial(
        widget.loan.serialNumber,
        newAmount,
      );

      // Update the local loan object
      setState(() {
        widget.loan.amountReceived = newAmount;
      });

      // Refresh loan calculations
      _loanController.refreshLoanCalculations();

      _showSnackbar(
        'Success',
        'Received amount updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isProcessingAction = false;
      });
    }
  }

  // Helper method to safely show snackbars
  void _showSnackbar(
    String title,
    String message, {
    Color? backgroundColor,
    Color? colorText,
  }) {
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
          backgroundColor: backgroundColor,
          colorText: colorText,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    } catch (e) {
      print('Error showing snackbar: $e');
    }
  }

  void _addPartialRepayment() {
    if (_isProcessingAction) return; // Prevent multiple simultaneous actions

    final amount =
        double.tryParse(_partialRepaymentAmountController.text) ?? 0.0;

    if (amount <= 0) {
      _showSnackbar(
        'Error',
        'Repayment amount must be greater than 0',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (amount > widget.loan.currentBalance) {
      _showSnackbar(
        'Error',
        'Repayment amount cannot exceed remaining balance',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isProcessingAction = true;
    });

    try {
      _loanController.addPartialRepayment(
        widget.loan.serialNumber,
        amount,
        DateTime.now(),
      );

      // Clear the input field
      _partialRepaymentAmountController.clear();

      // Refresh the page
      setState(() {});

      _showSnackbar(
        'Success',
        'Partial repayment added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isProcessingAction = false;
      });
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Delete Loan',
          ),
        ],
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
              UpdateReceivedAmountCard(
                loan: widget.loan,
                controller: _receivedAmountController,
                isProcessing: _isProcessingAction,
                onUpdate: _updateReceivedAmount,
              ),
              PartialRepaymentCard(
                loan: widget.loan,
                controller: _partialRepaymentAmountController,
                isProcessing: _isProcessingAction,
                onAddRepayment: _addPartialRepayment,
                partialRepayments: _loanController.getPartialRepayments(
                  widget.loan.serialNumber,
                ),
              ),
              AdditionalLoanCard(loan: widget.loan),
              DeleteLoanCard(
                loan: widget.loan,
                onDelete: _showDeleteConfirmation,
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
        UpdateReceivedAmountCard(
          loan: widget.loan,
          controller: _receivedAmountController,
          isProcessing: _isProcessingAction,
          onUpdate: _updateReceivedAmount,
        ),
        PartialRepaymentCard(
          loan: widget.loan,
          controller: _partialRepaymentAmountController,
          isProcessing: _isProcessingAction,
          onAddRepayment: _addPartialRepayment,
          partialRepayments: _loanController.getPartialRepayments(
            widget.loan.serialNumber,
          ),
        ),
        AdditionalLoanCard(loan: widget.loan),
        DeleteLoanCard(loan: widget.loan, onDelete: _showDeleteConfirmation),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Confirm Deletion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this loan?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Loan: ${widget.loan.name} - ${widget.loan.serialNumber}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Amount: NPR ${widget.loan.amountGiven.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: const Text(
                '⚠️ This action cannot be undone!',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _deleteLoan();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteLoan() {
    _loanController.deleteLoanBySerial(widget.loan.serialNumber);
    Get.back(); // Close dialog
    Get.back(); // Navigate back to loan list
    _showSnackbar(
      'Success',
      'Loan deleted successfully',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}
