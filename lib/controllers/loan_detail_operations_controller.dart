import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';

class LoanDetailOperationsController extends GetxController {
  final LoanController _loanController = Get.find<LoanController>();

  final receivedAmountController = TextEditingController();
  final durationOverrideInputController = TextEditingController(text: '');

  final isProcessingAction = false.obs;
  Timer? _updateTimer;

  late Loan _loan;
  Loan get loan => _loan;

  // Duration override: when set, UI should use custom-days interest instead of default
  final RxnInt _overrideDays = RxnInt();
  int? get overrideDays => _overrideDays.value;
  bool get isDurationOverrideActive =>
      _overrideDays.value != null && (_overrideDays.value ?? 0) > 0;

  // Computed values when override is active
  double get overrideInterest {
    final days = _overrideDays.value ?? 0;
    if (days <= 0) return 0.0;
    return _loan.calculateCustomDaysInterest(days);
  }

  double get overrideImmediateTotal {
    if (!isDurationOverrideActive) return 0.0;
    // Use remaining principal as base for total when overriding days
    return _loan.remainingPrincipal + overrideInterest;
  }

  double get overridePlannedDue {
    if (!isDurationOverrideActive) return 0.0;
    // Total due under override = (remaining principal + override interest) - amount received so far
    // Note: amountReceived has already been accounted into remainingPrincipal via ledger for principal.
    return overrideImmediateTotal -
        0.0; // remainingPrincipal already excludes received principal
  }

  double get overrideOutstandingNow {
    if (!isDurationOverrideActive) return 0.0;
    // Outstanding shown in tiles: principal + interest under override days
    return overrideImmediateTotal;
  }

  void initializeLoan(Loan loan) {
    _loan = loan;
    // Treat the input as an additional amount to add, so start with empty field
    receivedAmountController.text = '';
    durationOverrideInputController.text = '';
    _startPeriodicUpdates();
    _loadSavedOverrideDays();
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // Force UI update for real-time calculations
      update();
    });
  }

  Future<bool> updateReceivedAmount() async {
    if (isProcessingAction.value) return false;

    final addAmount =
        double.tryParse(receivedAmountController.text.trim()) ?? 0.0;

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

  // Duration override controls
  void activateDurationOverride(int days) {
    if (days <= 0) {
      _showErrorSnackbar('Duration must be greater than 0 days');
      return;
    }
    _overrideDays.value = days;
    _persistOverrideDays(days);
    update();
  }

  void clearDurationOverride() {
    _overrideDays.value = null;
    durationOverrideInputController.text = '';
    _removeSavedOverrideDays();
    update();
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

  // New payment methods for the updated system

  Future<bool> addInterestOnlyPayment(double interestAmount, int days) async {
    if (isProcessingAction.value) return false;

    if (interestAmount <= 0) {
      _showErrorSnackbar('Interest amount must be positive');
      return false;
    }

    if (days <= 0) {
      _showErrorSnackbar('Number of days must be positive');
      return false;
    }

    isProcessingAction.value = true;

    try {
      // Apply the interest collection immediately so UI and due update right away
      // We still calculate the amount for the selected days, but record it at 'now'
      final repaymentDate = DateTime.now();

      // Record interest-only repayment; ledger applies to interest first so principal stays intact
      _loanController.addPartialRepayment(
        _loan.serialNumber,
        interestAmount,
        repaymentDate,
      );

      // Sync local reference with the updated loan from controller
      final refreshed = _loanController.getLoanBySerial(_loan.serialNumber);
      if (refreshed != null) {
        _loan = refreshed;
      }

      // Refresh loan calculations and force UI update
      _loanController.refreshLoanCalculations();
      update();

      _showSuccessSnackbar('Interest payment recorded successfully');
      return true;
    } catch (e) {
      _showErrorSnackbar('Failed to record interest payment');
      return false;
    } finally {
      isProcessingAction.value = false;
    }
  }

  // Persistence helpers for duration override
  String get _overrideKey => 'override_days_${_loan.serialNumber}';

  Future<void> _loadSavedOverrideDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_overrideKey);
      if (saved != null && saved > 0) {
        _overrideDays.value = saved;
        durationOverrideInputController.text = saved.toString();
        update();
      }
    } catch (e) {
      // Ignore persistence errors silently
    }
  }

  Future<void> _persistOverrideDays(int days) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_overrideKey, days);
    } catch (e) {
      // Ignore persistence errors silently
    }
  }

  Future<void> _removeSavedOverrideDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_overrideKey);
    } catch (e) {
      // Ignore persistence errors silently
    }
  }

  Future<bool> addPrincipalOnlyPayment(double principalAmount) async {
    if (isProcessingAction.value) return false;

    if (principalAmount <= 0) {
      _showErrorSnackbar('Principal amount must be positive');
      return false;
    }

    final remainingPrincipal = _loan.remainingPrincipal;
    if (principalAmount > remainingPrincipal) {
      _showErrorSnackbar('Amount exceeds remaining principal');
      return false;
    }

    isProcessingAction.value = true;

    try {
      // Post at last event date so repayment goes straight to principal (no interim interest)
      final start = _loan.lastEventDate;

      // Add partial repayment - the loan's ledger system will handle principal reduction
      _loanController.addPartialRepayment(
        _loan.serialNumber,
        principalAmount,
        start,
      );

      // Sync local reference with the updated loan from controller
      final refreshed = _loanController.getLoanBySerial(_loan.serialNumber);
      if (refreshed != null) {
        _loan = refreshed;
      }

      // Refresh loan calculations and force UI update
      _loanController.refreshLoanCalculations();
      update();

      _showSuccessSnackbar('Principal payment recorded successfully');
      return true;
    } catch (e) {
      _showErrorSnackbar('Failed to record principal payment');
      return false;
    } finally {
      isProcessingAction.value = false;
    }
  }

  Future<bool> addPrincipalRepaymentWithInterest(
    double principalAmount,
    int days,
  ) async {
    if (isProcessingAction.value) return false;

    if (principalAmount <= 0) {
      _showErrorSnackbar('Principal amount must be positive');
      return false;
    }

    if (days < 0) {
      _showErrorSnackbar('Number of days cannot be negative');
      return false;
    }

    final remainingPrincipal = _loan.remainingPrincipal;
    if (principalAmount > remainingPrincipal + 0.0001) {
      _showErrorSnackbar('Amount exceeds remaining principal');
      return false;
    }

    isProcessingAction.value = true;

    try {
      // Start from last event date for accurate accrual segments
      final start = _loan.lastEventDate;

      // 1) Apply principal repayment at start
      _loanController.addPartialRepayment(
        _loan.serialNumber,
        principalAmount,
        start,
      );

      // Refresh loan to get updated remaining principal
      final afterPrincipal = _loanController.getLoanBySerial(
        _loan.serialNumber,
      );
      if (afterPrincipal != null) {
        _loan = afterPrincipal;
      }

      if (days > 0) {
        // 2) Compute interest for chosen days on new remaining principal
        final principalBase = _loan.remainingPrincipal;
        final interestAmount =
            (principalBase * _loan.dailyInterestRate * days) / 100.0;

        // 3) Collect that interest immediately so UI reflects payment now
        _loanController.addPartialRepayment(
          _loan.serialNumber,
          interestAmount,
          DateTime.now(),
        );

        // Reload
        final refreshed2 = _loanController.getLoanBySerial(_loan.serialNumber);
        if (refreshed2 != null) {
          _loan = refreshed2;
        }
      }

      _loanController.refreshLoanCalculations();
      update();
      _showSuccessSnackbar(
        'Principal repayment recorded' +
            (days > 0 ? ' with $days days interest' : ''),
      );
      return true;
    } catch (e) {
      _showErrorSnackbar('Failed to record principal repayment with interest');
      return false;
    } finally {
      isProcessingAction.value = false;
    }
  }

  Future<bool> addFullRepayment(double totalAmount) async {
    if (isProcessingAction.value) return false;

    if (totalAmount <= 0) {
      _showErrorSnackbar('Repayment amount must be positive');
      return false;
    }

    final totalDue = _loan.dueAmount;
    if (totalAmount < totalDue - 0.01) {
      // Allow small rounding differences
      _showErrorSnackbar('Amount is less than total due');
      return false;
    }

    isProcessingAction.value = true;

    try {
      final now = DateTime.now();

      // Add full repayment as settlement to enforce min 30-day rule
      _loanController.addPartialRepaymentForSettlement(
        _loan.serialNumber,
        totalDue,
        now,
      );

      // Sync local reference with the updated loan from controller
      final refreshed = _loanController.getLoanBySerial(_loan.serialNumber);
      if (refreshed != null) {
        _loan = refreshed;
      }

      // Refresh loan calculations and force UI update
      _loanController.refreshLoanCalculations();
      update();

      _showSuccessSnackbar('Full repayment recorded successfully');
      return true;
    } catch (e) {
      _showErrorSnackbar('Failed to record full repayment');
      return false;
    } finally {
      isProcessingAction.value = false;
    }
  }

  // New: top up existing loan (increase principal)
  Future<bool> addTopUp(double amount) async {
    if (isProcessingAction.value) return false;
    if (amount <= 0) {
      _showErrorSnackbar('Top-up amount must be positive');
      return false;
    }
    isProcessingAction.value = true;
    try {
      _loanController.addTopUp(_loan.serialNumber, amount, DateTime.now());
      final refreshed = _loanController.getLoanBySerial(_loan.serialNumber);
      if (refreshed != null) {
        _loan = refreshed;
      }
      _loanController.refreshLoanCalculations();
      update();
      _showSuccessSnackbar('Top-up of NPR ${amount.toStringAsFixed(2)} added');
      return true;
    } catch (e) {
      _showErrorSnackbar('Failed to add top-up');
      return false;
    } finally {
      isProcessingAction.value = false;
    }
  }

  // New: overall payment - apply any amount now; will go to interest first, then principal
  Future<bool> addOverallPayment(double amount) async {
    if (isProcessingAction.value) return false;
    if (amount <= 0) {
      _showErrorSnackbar('Payment amount must be positive');
      return false;
    }
    // Prevent overpayment beyond settlement outstanding due now (min-30 enforced)
    final outstanding = _loanController.getOutstandingDueForSettlement(
      _loan.serialNumber,
    );
    if (amount - outstanding > 0.005) {
      _showErrorSnackbar(
        'Amount exceeds outstanding due (NPR ${outstanding.toStringAsFixed(2)})',
      );
      return false;
    }
    isProcessingAction.value = true;
    try {
      _loanController.addPartialRepaymentForSettlement(
        _loan.serialNumber,
        amount,
        DateTime.now(),
      );
      final refreshed = _loanController.getLoanBySerial(_loan.serialNumber);
      if (refreshed != null) {
        _loan = refreshed;
      }
      _loanController.refreshLoanCalculations();
      update();
      _showSuccessSnackbar('Payment recorded successfully');
      return true;
    } catch (e) {
      _showErrorSnackbar('Failed to record payment');
      return false;
    } finally {
      isProcessingAction.value = false;
    }
  }

  Future<bool> addCustomDaysPayment(double interestAmount, int days) async {
    if (isProcessingAction.value) return false;

    if (interestAmount <= 0) {
      _showErrorSnackbar('Interest amount must be positive');
      return false;
    }

    if (days <= 0) {
      _showErrorSnackbar('Number of days must be positive');
      return false;
    }

    isProcessingAction.value = true;

    try {
      // Record the interest payment immediately so UI reflects the change now
      final repaymentDate = DateTime.now();

      // Add the interest payment for custom days
      _loanController.addPartialRepayment(
        _loan.serialNumber,
        interestAmount,
        repaymentDate,
      );

      // Sync local reference with the updated loan from controller
      final refreshed = _loanController.getLoanBySerial(_loan.serialNumber);
      if (refreshed != null) {
        _loan = refreshed;
      }

      // Refresh loan calculations and force UI update
      _loanController.refreshLoanCalculations();
      update();

      _showSuccessSnackbar('Custom interest payment recorded successfully');
      return true;
    } catch (e) {
      _showErrorSnackbar('Failed to record custom interest payment');
      return false;
    } finally {
      isProcessingAction.value = false;
    }
  }

  @override
  void onClose() {
    receivedAmountController.dispose();
    durationOverrideInputController.dispose();
    _updateTimer?.cancel();
    super.onClose();
  }
}
