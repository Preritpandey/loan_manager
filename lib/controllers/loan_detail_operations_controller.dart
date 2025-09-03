import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/loan_detail_page.dart';

class LoanDetailOperationsController extends GetxController {
  final LoanController _loanController = Get.find<LoanController>();

  final receivedAmountController = TextEditingController();

  final isProcessingAction = false.obs;
  Timer? _updateTimer;

  late Loan _loan;
  Loan get loan => _loan;

  void initializeLoan(Loan loan) {
    _loan = loan;
    // Treat the input as an additional amount to add, so start with empty field
    receivedAmountController.text = '';
    _startPeriodicUpdates();
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Force UI update for real-time calculations
      update();
    });
  }

  Future<bool> updateReceivedAmount() async {
    if (isProcessingAction.value) return false;

    final addAmount = double.tryParse(receivedAmountController.text.trim()) ?? 0.0;

    // For updates, treat input as an additional amount to add
    if (addAmount <= 0) {
      _showErrorSnackbar('Please enter a positive amount to add');
      return false;
    }

    // Validate against outstanding due to prevent overpayment
    final outstanding = _loanController.getOutstandingDue(_loan.serialNumber);
    if (addAmount - outstanding > 0.005) {
      _showErrorSnackbar(
        'Amount exceeds outstanding due (NPR ${outstanding.toStringAsFixed(2)})',
      );
      return false;
    }

    isProcessingAction.value = true;

    try {
      // Record as a partial repayment with today's date
      final now = DateTime.now();
      _loanController.addPartialRepayment(_loan.serialNumber, addAmount, now);

      // Sync local reference with the updated loan from controller
      final refreshed = _loanController.getLoanBySerial(_loan.serialNumber);
      if (refreshed != null) {
        _loan = refreshed;
      }

      // Refresh loan calculations and force UI update
      _loanController.refreshLoanCalculations();

      // Clear the input field after successful update
      receivedAmountController.text = '';

      // Force immediate UI rebuild
      update();

      _showSuccessSnackbar('Repayment added successfully');
      return true;
    } catch (e) {
      _showErrorSnackbar('Failed to update received amount');
      return false;
    } finally {
      isProcessingAction.value = false;
    }
  }

  bool _validateReceivedAmount(double amount) {
    if (amount < 0) {
      _showErrorSnackbar('Received amount cannot be negative');
      return false;
    }
    return true;
  }

  Future<bool> deleteLoan() async {
    try {
      _loanController.deleteLoanBySerial(_loan.serialNumber);
      _showSuccessSnackbar('Loan deleted successfully');

      return true;
    } catch (e) {
      _showErrorSnackbar('Failed to delete loan');
      return false;
    }
  }

  void showDeleteConfirmationDialog() {
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
        content: _buildDeleteConfirmationContent(),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              deleteLoan();
              Get.back();
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

  Widget _buildDeleteConfirmationContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Are you sure you want to delete this loan?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          'Loan: ${_loan.name} - ${_loan.serialNumber}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          'Amount: NPR ${_loan.amountGiven.toStringAsFixed(2)}',
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
    );
  }

  void _showSuccessSnackbar(String message) {
    _showSnackbar('Success', message, Colors.green, Colors.white);
  }

  void _showErrorSnackbar(String message) {
    _showSnackbar('Error', message, Colors.red, Colors.white);
  }

  void _showSnackbar(
    String title,
    String message,
    Color backgroundColor,
    Color colorText,
  ) {
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

  @override
  void onClose() {
    receivedAmountController.dispose();
    _updateTimer?.cancel();
    super.onClose();
  }
}
