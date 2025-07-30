import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/add_additional_loan_page.dart';
import 'dart:async'; // Added for Timer

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const InfoCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class LoanDetailPage extends StatefulWidget {
  final Loan loan;

  const LoanDetailPage({super.key, required this.loan});

  @override
  State<LoanDetailPage> createState() => _LoanDetailPageState();
}

class _LoanDetailPageState extends State<LoanDetailPage> {
  final TextEditingController _receivedAmountController =
      TextEditingController();
  final LoanController _loanController = Get.find<LoanController>();
  Timer? _updateTimer;
  bool _isEarlyRepaymentEnabled = false;

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
    _updateTimer?.cancel();
    super.dispose();
  }

  // Calculate early repayment amount
  double get _earlyRepaymentAmount {
    if (!_isEarlyRepaymentEnabled) return widget.loan.immediateTotalDue;

    final daysPassed = widget.loan.daysPassed;
    final actualInterest =
        (widget.loan.amountGiven * widget.loan.interestRate) / 100 * daysPassed;
    return widget.loan.amountGiven + actualInterest;
  }

  // Calculate early repayment interest
  double get _earlyRepaymentInterest {
    if (!_isEarlyRepaymentEnabled) return widget.loan.agreedPeriodInterest;

    final daysPassed = widget.loan.daysPassed;
    return (widget.loan.amountGiven * widget.loan.interestRate) /
        100 *
        daysPassed;
  }

  // Calculate early repayment due amount
  double get _earlyRepaymentDueAmount {
    return _earlyRepaymentAmount - widget.loan.amountReceived;
  }

  void _updateReceivedAmount() {
    final newAmount = double.tryParse(_receivedAmountController.text) ?? 0.0;

    if (newAmount < 0) {
      Get.snackbar(
        'Error',
        'Received amount cannot be negative',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

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

    Get.snackbar(
      'Success',
      'Received amount updated successfully',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loan Details - ${widget.loan.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Delete Loan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoCard(
              title: 'Personal Information',
              children: [
                InfoRow(label: 'Name', value: widget.loan.name),
                InfoRow(label: 'Phone', value: widget.loan.phone),
                InfoRow(label: 'Address', value: widget.loan.address),
              ],
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Loan Information',
              children: [
                InfoRow(
                  label: 'Loan Date',
                  value: _formatDate(widget.loan.date),
                ),
                InfoRow(
                  label: 'Duration',
                  value: '${widget.loan.duration} days',
                ),
                InfoRow(
                  label: 'Interest Rate',
                  value: '${widget.loan.interestRate}%',
                ),
                InfoRow(
                  label: 'Loan Amount',
                  value: 'NPR ${widget.loan.amountGiven.toStringAsFixed(2)}',
                ),
                InfoRow(
                  label: 'Due Date',
                  value: _formatDate(
                    widget.loan.date.add(Duration(days: widget.loan.duration)),
                  ),
                ),
                InfoRow(
                  label: 'Days Remaining',
                  value: '${widget.loan.daysRemaining} days',
                  color: widget.loan.daysRemaining < 0
                      ? Colors.red
                      : Colors.green,
                ),
                if (widget.loan.isOverdue)
                  InfoRow(
                    label: 'Overdue Days',
                    value: '${widget.loan.overdueDays} days',
                    color: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Jewellery Information',
              children: [
                InfoRow(label: 'Type', value: widget.loan.type),
                InfoRow(
                  label: 'Jewellery Name',
                  value: widget.loan.jewelleryName,
                ),
                InfoRow(
                  label: 'Serial Number',
                  value: widget.loan.serialNumber,
                ),
              ],
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: 'Financial Summary',
              children: [
                InfoRow(
                  label: 'Principal Amount',
                  value: 'NPR ${widget.loan.amountGiven.toStringAsFixed(2)}',
                ),
                InfoRow(
                  label: 'Interest Rate',
                  value: '${widget.loan.interestRate}% daily',
                ),
                InfoRow(
                  label: 'Duration',
                  value: '${widget.loan.duration} days',
                ),
                InfoRow(
                  label: 'Days Passed',
                  value: '${widget.loan.daysPassed} days',
                ),
                InfoRow(
                  label: 'Due Date',
                  value: _formatDate(widget.loan.dueDate),
                ),
                if (widget.loan.daysPassed <= widget.loan.duration) ...[
                  InfoRow(
                    label: 'Days Remaining',
                    value: '${widget.loan.daysRemaining} days',
                    color: widget.loan.daysRemaining > 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ] else ...[
                  InfoRow(
                    label: 'Overdue Days',
                    value: '${widget.loan.overdueDays} days',
                    color: Colors.red,
                  ),
                ],
                const Divider(),
                InfoRow(
                  label: 'Full Interest (Fixed)',
                  value:
                      'NPR ${widget.loan.agreedPeriodInterest.toStringAsFixed(2)}',
                  color: Colors.orange,
                ),
                InfoRow(
                  label: 'Total Due (Principal + Full Interest)',
                  value:
                      'NPR ${widget.loan.immediateTotalDue.toStringAsFixed(2)}',
                  color: Colors.blue,
                ),
                if (_isEarlyRepaymentEnabled &&
                    widget.loan.daysPassed < widget.loan.duration) ...[
                  const Divider(),
                  InfoRow(
                    label: 'Early Repayment Interest',
                    value: 'NPR ${_earlyRepaymentInterest.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                  InfoRow(
                    label: 'Early Repayment Total',
                    value: 'NPR ${_earlyRepaymentAmount.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                  const Divider(),
                ],
                if (widget.loan.isOverdue) ...[
                  InfoRow(
                    label: 'Additional Overdue Interest',
                    value:
                        'NPR ${widget.loan.overdueInterest.toStringAsFixed(2)}',
                    color: Colors.red,
                  ),
                  InfoRow(
                    label: 'Total Interest (Including Overdue)',
                    value:
                        'NPR ${widget.loan.currentInterest.toStringAsFixed(2)}',
                    color: Colors.orange,
                  ),
                ],
                const Divider(),
                InfoRow(
                  label: 'Amount Received',
                  value: 'NPR ${widget.loan.amountReceived.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
                InfoRow(
                  label: 'Remaining Amount',
                  value:
                      _isEarlyRepaymentEnabled &&
                          widget.loan.daysPassed < widget.loan.duration
                      ? 'NPR ${(_earlyRepaymentAmount - widget.loan.amountReceived).toStringAsFixed(2)}'
                      : 'NPR ${(widget.loan.immediateTotalDue - widget.loan.amountReceived).toStringAsFixed(2)}',
                ),
                const Divider(),
                InfoRow(
                  label: 'Total Due',
                  value:
                      _isEarlyRepaymentEnabled &&
                          widget.loan.daysPassed < widget.loan.duration
                      ? 'NPR ${_earlyRepaymentDueAmount.toStringAsFixed(2)}'
                      : 'NPR ${widget.loan.dueAmount.toStringAsFixed(2)}',
                  color:
                      _isEarlyRepaymentEnabled &&
                          widget.loan.daysPassed < widget.loan.duration
                      ? (_earlyRepaymentDueAmount > 0
                            ? Colors.red
                            : Colors.green)
                      : (widget.loan.dueAmount > 0 ? Colors.red : Colors.green),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'LOAN TERMS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _isEarlyRepaymentEnabled &&
                                widget.loan.daysPassed < widget.loan.duration
                            ? 'Early repayment enabled: Customer pays interest only for actual days (${widget.loan.daysPassed} days). '
                                  'Total due: NPR ${_earlyRepaymentAmount.toStringAsFixed(2)}'
                            : 'Full interest is calculated and added to principal immediately when loan is given. '
                                  'Customer must pay the full amount (Principal + Full Interest) regardless of early payment.',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (widget.loan.isFullyPaid) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'FULLY PAID',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (widget.loan.isOverdue) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '⚠️ OVERDUE NOTICE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This loan is ${widget.loan.overdueDays} days overdue. '
                          'Additional interest of NPR ${widget.loan.overdueInterest.toStringAsFixed(2)} has been added to the total due amount.',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (widget.loan.description.isNotEmpty) ...[
              InfoCard(
                title: 'Description',
                children: [InfoRow(label: '', value: widget.loan.description)],
              ),
              const SizedBox(height: 16),
            ],
            _buildCustomerSummaryCard(),
            const SizedBox(height: 16),
            _buildUpdateReceivedAmountCard(),
            const SizedBox(height: 16),
            _buildEarlyRepaymentCard(),
            const SizedBox(height: 16),
            _buildAdditionalLoanCard(),
            const SizedBox(height: 16),
            _buildDeleteLoanCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateReceivedAmountCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Received Amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _receivedAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Received Amount (NPR)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateReceivedAmount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Update Received Amount',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildAdditionalLoanCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Loan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Give additional loan to this customer',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(
                  () => AddAdditionalLoanPage(existingLoan: widget.loan),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Give Additional Loan',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSummaryCard() {
    final customerLoans = _loanController.getLoansByCustomerName(
      widget.loan.name,
    );
    final totalDueAmount = _loanController.getTotalDueAmountForCustomer(
      widget.loan.name,
    );
    final totalAmountGiven = customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.amountGiven,
    );
    final totalAmountReceived = customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.amountReceived,
    );
    final totalCompoundInterest = _loanController
        .getTotalCompoundInterestForCustomer(widget.loan.name);
    final totalOverdueInterest = _loanController
        .getTotalOverdueInterestForCustomer(widget.loan.name);
    final isOverdue = _loanController.isCustomerOverdue(widget.loan.name);
    final totalOverdueDays = _loanController.getTotalOverdueDaysForCustomer(
      widget.loan.name,
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Customer Summary - ${widget.loan.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'OVERDUE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            InfoRow(
              label: 'Total Loans',
              value: customerLoans.length.toString(),
            ),
            InfoRow(
              label: 'Total Given',
              value: 'NPR ${totalAmountGiven.toStringAsFixed(2)}',
            ),
            InfoRow(
              label: 'Total Received',
              value: 'NPR ${totalAmountReceived.toStringAsFixed(2)}',
            ),
            InfoRow(
              label: 'Total Interest',
              value: 'NPR ${totalCompoundInterest.toStringAsFixed(2)}',
            ),
            if (totalOverdueInterest > 0)
              InfoRow(
                label: 'Overdue Interest',
                value: 'NPR ${totalOverdueInterest.toStringAsFixed(2)}',
                color: Colors.red,
              ),
            InfoRow(
              label: 'Total Due',
              value: 'NPR ${totalDueAmount.toStringAsFixed(2)}',
              color: totalDueAmount > 0 ? Colors.red : Colors.green,
            ),
            if (isOverdue)
              InfoRow(
                label: 'Total Overdue Days',
                value: '$totalOverdueDays days',
                color: Colors.red,
              ),
            if (customerLoans.length > 1) ...[
              const SizedBox(height: 16),
              const Text(
                'All Loans:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...customerLoans
                  .map(
                    (loan) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${loan.type} - ${loan.jewelleryName} (${loan.serialNumber})',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '${loan.interestRate}% - ${loan.duration} days',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'NPR ${loan.amountGiven.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (loan.isOverdue)
                                Text(
                                  '${loan.overdueDays} days overdue',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEarlyRepaymentCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Early Repayment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Early Repayment Calculation'),
              value: _isEarlyRepaymentEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isEarlyRepaymentEnabled = value;
                });
              },
            ),
            if (_isEarlyRepaymentEnabled) ...[
              const SizedBox(height: 16),
              InfoRow(
                label: 'Early Repayment Amount',
                value: 'NPR ${_earlyRepaymentAmount.toStringAsFixed(2)}',
              ),
              InfoRow(
                label: 'Early Repayment Interest',
                value: 'NPR ${_earlyRepaymentInterest.toStringAsFixed(2)}',
              ),
              InfoRow(
                label: 'Early Repayment Due Amount',
                value: 'NPR ${_earlyRepaymentDueAmount.toStringAsFixed(2)}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteLoanCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delete Loan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Permanently delete this loan. This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showDeleteConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Delete Loan',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
          'Are you sure you want to delete this loan? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _deleteLoan();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
    Get.snackbar(
      'Success',
      'Loan deleted successfully',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}
