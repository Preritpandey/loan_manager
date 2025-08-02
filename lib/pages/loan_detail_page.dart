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
  final IconData? icon;
  final bool isAmount;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.isAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: isMobile ? 100 : 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: isAmount
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : EdgeInsets.zero,
              decoration: isAmount
                  ? BoxDecoration(
                      color: (color ?? Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (color ?? Colors.blue).withOpacity(0.3),
                      ),
                    )
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: isAmount ? FontWeight.bold : FontWeight.w600,
                  color: color ?? Colors.black87,
                  fontSize: isAmount
                      ? (isMobile ? 13 : 15)
                      : (isMobile ? 12 : 14),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
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
  final IconData? titleIcon;
  final Color? titleColor;

  const InfoCard({
    super.key,
    required this.title,
    required this.children,
    this.titleIcon,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey[50]!],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (titleIcon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (titleColor ?? Colors.blue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        titleIcon,
                        color: titleColor ?? Colors.blue,
                        size: isMobile ? 18 : 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor ?? Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isMobile ? 14 : 16),
          SizedBox(width: isMobile ? 4 : 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
                _buildStatusHeader(),

                if (isDesktop) _buildDesktopLayout() else _buildMobileLayout(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NPR ${widget.loan.amountGiven.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Principal Amount',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'NPR ${widget.loan.dueAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: widget.loan.dueAmount > 0
                            ? Colors.red[300]
                            : Colors.green[300],
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Amount Due',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.loan.isFullyPaid)
                StatusBadge(
                  text: 'FULLY PAID',
                  color: Colors.green[300]!,
                  icon: Icons.check_circle,
                )
              else if (widget.loan.isOverdue)
                StatusBadge(
                  text: '${widget.loan.overdueDays} DAYS OVERDUE',
                  color: Colors.red[300]!,
                  icon: Icons.warning,
                )
              else
                StatusBadge(
                  text: '${widget.loan.daysRemaining} DAYS LEFT',
                  color: Colors.orange[300]!,
                  icon: Icons.schedule,
                ),
              StatusBadge(
                text: '${widget.loan.interestRate}% DAILY',
                color: Colors.purple[300]!,
                icon: Icons.percent,
              ),
            ],
          ),
        ],
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
              _buildPersonalInfoCard(),
              _buildLoanInfoCard(),
              _buildJewelleryInfoCard(),
              if (widget.loan.description.isNotEmpty) _buildDescriptionCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildFinancialSummaryCard(),
              _buildCustomerSummaryCard(),
              _buildUpdateReceivedAmountCard(),
              _buildPartialRepaymentCard(),
              _buildAdditionalLoanCard(),
              _buildDeleteLoanCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildPersonalInfoCard(),
        _buildLoanInfoCard(),
        _buildJewelleryInfoCard(),
        _buildFinancialSummaryCard(),
        if (widget.loan.description.isNotEmpty) _buildDescriptionCard(),
        _buildCustomerSummaryCard(),
        _buildUpdateReceivedAmountCard(),
        _buildPartialRepaymentCard(),
        _buildAdditionalLoanCard(),
        _buildDeleteLoanCard(),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return InfoCard(
      title: 'Personal Information',
      titleIcon: Icons.person,
      titleColor: Colors.blue[700],
      children: [
        InfoRow(
          label: 'Name',
          value: widget.loan.name,
          icon: Icons.person_outline,
        ),
        InfoRow(
          label: 'Phone',
          value: widget.loan.phone,
          icon: Icons.phone_outlined,
        ),
        InfoRow(
          label: 'Address',
          value: widget.loan.address,
          icon: Icons.location_on_outlined,
        ),
      ],
    );
  }

  Widget _buildLoanInfoCard() {
    return InfoCard(
      title: 'Loan Information',
      titleIcon: Icons.receipt_long,
      titleColor: Colors.green[700],
      children: [
        InfoRow(
          label: 'Loan Date',
          value: _formatDate(widget.loan.date),
          icon: Icons.calendar_today,
        ),
        InfoRow(
          label: 'Duration',
          value: '${widget.loan.duration} days',
          icon: Icons.schedule,
        ),
        InfoRow(
          label: 'Interest Rate',
          value: '${widget.loan.interestRate}%',
          icon: Icons.percent,
        ),
        InfoRow(
          label: 'Due Date',
          value: _formatDate(
            widget.loan.date.add(Duration(days: widget.loan.duration)),
          ),
          icon: Icons.event,
        ),
        InfoRow(
          label: 'Days Passed',
          value: '${widget.loan.daysPassed} days',
          icon: Icons.timelapse,
        ),
        if (widget.loan.isOverdue)
          InfoRow(
            label: 'Overdue Days',
            value: '${widget.loan.overdueDays} days',
            color: Colors.red,
            icon: Icons.warning,
          )
        else
          InfoRow(
            label: 'Days Remaining',
            value: '${widget.loan.daysRemaining} days',
            color: widget.loan.daysRemaining > 0 ? Colors.green : Colors.red,
            icon: Icons.schedule,
          ),
      ],
    );
  }

  Widget _buildJewelleryInfoCard() {
    return InfoCard(
      title: 'Collateral Information',
      titleIcon: Icons.diamond,
      titleColor: Colors.orange[700],
      children: [
        InfoRow(label: 'Type', value: widget.loan.type, icon: Icons.category),
        InfoRow(
          label: 'Jewellery Name',
          value: widget.loan.jewelleryName,
          icon: Icons.diamond_outlined,
        ),
        InfoRow(
          label: 'Serial Number',
          value: widget.loan.serialNumber,
          icon: Icons.qr_code,
        ),
      ],
    );
  }

  Widget _buildFinancialSummaryCard() {
    return InfoCard(
      title: 'Financial Summary',
      titleIcon: Icons.account_balance_wallet,
      titleColor: Colors.purple[700],
      children: [
        InfoRow(
          label: 'Principal Amount',
          value: 'NPR ${widget.loan.amountGiven.toStringAsFixed(2)}',
          color: Colors.blue[700],
          icon: Icons.attach_money,
          isAmount: true,
        ),
        InfoRow(
          label: 'Full Interest',
          value: 'NPR ${widget.loan.agreedPeriodInterest.toStringAsFixed(2)}',
          color: Colors.orange[700],
          icon: Icons.trending_up,
          isAmount: true,
        ),
        InfoRow(
          label: 'Total Due (P+I)',
          value: 'NPR ${widget.loan.immediateTotalDue.toStringAsFixed(2)}',
          color: Colors.blue[700],
          icon: Icons.calculate,
          isAmount: true,
        ),

        if (widget.loan.isOverdue) ...[
          const Divider(height: 20),
          InfoRow(
            label: 'Overdue Interest',
            value: 'NPR ${widget.loan.overdueInterest.toStringAsFixed(2)}',
            color: Colors.red[700],
            icon: Icons.warning,
            isAmount: true,
          ),
          InfoRow(
            label: 'Total Interest',
            value: 'NPR ${widget.loan.currentInterest.toStringAsFixed(2)}',
            color: Colors.orange[700],
            icon: Icons.trending_up,
            isAmount: true,
          ),
        ],

        const Divider(height: 20),
        InfoRow(
          label: 'Amount Received',
          value: 'NPR ${widget.loan.amountReceived.toStringAsFixed(2)}',
          color: Colors.green[700],
          icon: Icons.payment,
          isAmount: true,
        ),
        InfoRow(
          label: 'Amount Due',
          value: 'NPR ${widget.loan.dueAmount.toStringAsFixed(2)}',
          color: widget.loan.dueAmount > 0
              ? Colors.red[700]
              : Colors.green[700],
          icon: Icons.account_balance,
          isAmount: true,
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return InfoCard(
      title: 'Description',
      titleIcon: Icons.notes,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            widget.loan.description,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateReceivedAmountCard() {
    return InfoCard(
      title: 'Update Received Amount',
      titleIcon: Icons.edit,
      titleColor: Colors.green[700],
      children: [
        TextField(
          controller: _receivedAmountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Received Amount (NPR)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.attach_money),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessingAction ? null : _updateReceivedAmount,
            icon: _isProcessingAction
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.update),
            label: Text(_isProcessingAction ? 'Updating...' : 'Update Amount'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartialRepaymentCard() {
    final partialRepayments = _loanController.getPartialRepayments(
      widget.loan.serialNumber,
    );

    return InfoCard(
      title: 'Partial Repayments',
      titleIcon: Icons.payment,
      titleColor: Colors.purple[700],
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Text(
                'Current Balance: NPR ${widget.loan.currentBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.purple[700],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _partialRepaymentAmountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Repayment Amount (NPR)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.payment),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Date: ${_formatDate(DateTime.now())}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              TextButton.icon(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: widget.loan.date,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != DateTime.now()) {
                    setState(() {
                      // No need to update _selectedRepaymentDate, as it's not used in _addPartialRepayment
                    });
                  }
                },
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Change'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessingAction ? null : _addPartialRepayment,
            icon: _isProcessingAction
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline),
            label: Text(
              _isProcessingAction ? 'Processing...' : 'Add Repayment',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (partialRepayments.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Divider(),
          Row(
            children: [
              Icon(Icons.history, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Repayment History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...partialRepayments
              .map(
                (repayment) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(repayment.date),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'NPR ${repayment.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildAdditionalLoanCard() {
    return InfoCard(
      title: 'Additional Loan',
      titleIcon: Icons.add_circle,
      titleColor: Colors.orange[700],
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Give additional loan to this customer with same collateral',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () =>
                Get.to(() => AddAdditionalLoanPage(existingLoan: widget.loan)),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Give Additional Loan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
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

    return InfoCard(
      title: 'Customer Summary - ${widget.loan.name}',
      titleIcon: Icons.person_pin,
      titleColor: Colors.indigo[700],
      children: [
        if (isOverdue)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customer has overdue loans! Total overdue: $totalOverdueDays days',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Total Loans',
                customerLoans.length.toString(),
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryItem(
                'Total Given',
                'NPR ${totalAmountGiven.toStringAsFixed(0)}',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Total Received',
                'NPR ${totalAmountReceived.toStringAsFixed(0)}',
                Icons.payment,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryItem(
                'Total Due',
                'NPR ${totalDueAmount.toStringAsFixed(0)}',
                Icons.account_balance,
                totalDueAmount > 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),

        if (customerLoans.length > 1) ...[
          const SizedBox(height: 20),
          const Divider(),
          Row(
            children: [
              Icon(Icons.list, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'All Loans (${customerLoans.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...customerLoans
              .map(
                (loan) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: loan.serialNumber == widget.loan.serialNumber
                        ? Colors.blue[50]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: loan.serialNumber == widget.loan.serialNumber
                          ? Colors.blue[300]!
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${loan.type} - ${loan.jewelleryName}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (loan.serialNumber == widget.loan.serialNumber)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${loan.interestRate}% • ${loan.duration} days • ${loan.serialNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'NPR ${loan.amountGiven.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (loan.isOverdue) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${loan.overdueDays}d',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteLoanCard() {
    return InfoCard(
      title: 'Danger Zone',
      titleIcon: Icons.warning,
      titleColor: Colors.red[700],
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Permanently delete this loan. This action cannot be undone.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete_forever),
            label: const Text('Delete Loan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
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
