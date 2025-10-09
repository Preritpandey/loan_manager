import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';
import 'package:list/controllers/loan_detail_operations_controller.dart';
import 'package:list/utils/nepali_date_utils.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as picker;

class PaymentOptionsCard extends StatefulWidget {
  final Loan loan;

  const PaymentOptionsCard({super.key, required this.loan});

  @override
  State<PaymentOptionsCard> createState() => _PaymentOptionsCardState();
}

class _PaymentOptionsCardState extends State<PaymentOptionsCard> {
  final LoanDetailOperationsController _controller =
      Get.find<LoanDetailOperationsController>();

  // Controllers for different payment types
  final TextEditingController _interestOnlyController = TextEditingController();
  final TextEditingController _principalOnlyController =
      TextEditingController();
  final TextEditingController _principalDaysController = TextEditingController(
    text: '0',
  );

  // State variables
  int _selectedInterestDays = 30;
  double _calculatedInterest = 0.0;
  double _remainingPrincipal = 0.0;
  double _overallPaymentAmount = 0.0;
  bool _showConfirmation = false;
  String _confirmationType = '';
  double _confirmationAmount = 0.0;
  int _confirmationDays = 0;

  // Selected collection date (BS)
  NepaliDate _selectedNepaliDate = NepaliDate.today();

  @override
  void initState() {
    super.initState();
    _updateCalculations();
  }

  @override
  void didUpdateWidget(covariant PaymentOptionsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCalculations();
  }

  @override
  void dispose() {
    _interestOnlyController.dispose();
    _principalOnlyController.dispose();
    _principalDaysController.dispose();
    super.dispose();
  }

  void _updateCalculations() {
    setState(() {
      _calculatedInterest = _calculateInterestForDays(_selectedInterestDays);
      _remainingPrincipal = widget.loan.remainingPrincipal;
    });
  }

  double _calculateInterestForDays(int days) {
    return (widget.loan.remainingPrincipal *
            widget.loan.dailyInterestRate *
            days) /
        100;
  }

  void _showConfirmationDialog(String type, double amount, {int days = 0}) {
    setState(() {
      _showConfirmation = true;
      _confirmationType = type;
      _confirmationAmount = amount;
      _confirmationDays = days;
    });
  }

  void _processPayment() async {
    // Process the payment based on type
    switch (_confirmationType) {
      case 'interest':
        await _processInterestPayment();
        break;
      case 'principal':
        await _processPrincipalPayment();
        break;
      case 'overall':
        await _processOverallPayment();
        break;
      case 'topup':
        await _processTopUp();
        break;
    }

    _hideConfirmation();
    _clearInputs();
    _updateCalculations();
  }

  Future<void> _processInterestPayment() async {
    // Add interest-only payment
    final success = await _controller.addInterestOnlyPayment(
      _confirmationAmount,
      _confirmationDays,
      _selectedNepaliDate.toGregorian(),
    );
    if (success) {
      _showSuccessSnackbar(
        'Interest payment of NPR ${_confirmationAmount.toStringAsFixed(2)} recorded for $_confirmationDays days',
      );
    }
  }

  Future<void> _processPrincipalPayment() async {
    // Add principal payment with optional days-based interest
    final success = await _controller.addPrincipalRepaymentWithInterest(
      _confirmationAmount,
      _confirmationDays,
      _selectedNepaliDate.toGregorian(),
    );
    if (success) {
      if (_confirmationDays > 0) {
        _showSuccessSnackbar(
          'Principal payment of NPR ${_confirmationAmount.toStringAsFixed(2)} with $_confirmationDays days interest recorded',
        );
      } else {
        _showSuccessSnackbar(
          'Principal payment of NPR ${_confirmationAmount.toStringAsFixed(2)} recorded',
        );
      }
    }
  }

  void _hideConfirmation() {
    setState(() {
      _showConfirmation = false;
      _confirmationType = '';
      _confirmationAmount = 0.0;
      _confirmationDays = 0;
    });
  }

  void _clearInputs() {
    _interestOnlyController.clear();
    _principalOnlyController.clear();
    _overallPaymentAmount = 0.0;
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[800],
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Payment Options',
      titleIcon: Icons.payment,
      titleColor: Colors.blue[700],
      children: [
        if (_showConfirmation) _buildConfirmationSection(),
        if (!_showConfirmation) ...[
          _buildInterestOnlySection(),
          const SizedBox(height: 20),
          _buildPrincipalOnlySection(),
          const SizedBox(height: 20),
          _buildOverallPaymentSection(),
          const SizedBox(height: 20),
          _buildTopUpSection(),
        ],
      ],
    );
  }

  Widget _buildInterestOnlySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.percent, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Interest-Only Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Principal remains unchanged. Choose number of days to charge interest for:',
            style: TextStyle(color: Colors.orange[800], fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Quick day selection buttons + custom option
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...[10, 30, 60, 90, 180, 365].map(
                (days) =>
                    _buildDayButton(days, _selectedInterestDays == days, () {
                      setState(() {
                        _selectedInterestDays = days;
                        _updateCalculations();
                      });
                    }),
              ),
              GestureDetector(
                onTap: () async {
                  await _showCustomDayInput(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Text(
                    'Custom…',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Interest calculation display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              children: [
                _buildCalculationRow(
                  'Remaining Principal',
                  'NPR ${_remainingPrincipal.toStringAsFixed(2)}',
                ),
                _buildCalculationRow('Days', '$_selectedInterestDays days'),
                _buildCalculationRow(
                  'Daily Rate',
                  '${widget.loan.dailyInterestRate.toStringAsFixed(4)}%',
                ),
                const Divider(),
                _buildCalculationRow(
                  'Interest Amount',
                  'NPR ${_calculatedInterest.toStringAsFixed(2)}',
                  isResult: true,
                  color: Colors.orange[700],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showConfirmationDialog(
                'interest',
                _calculatedInterest,
                days: _selectedInterestDays,
              ),
              icon: const Icon(Icons.percent),
              label: Text(
                'Collect Interest (NPR ${_calculatedInterest.toStringAsFixed(2)})',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipalOnlySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                'Principal-Only Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reduces principal balance. Optionally collect interest for custom days after reduction.',
            style: TextStyle(color: Colors.green[800], fontSize: 12),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _principalOnlyController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: 'Principal Payment Amount (NPR)',
              hintText: 'Max: NPR ${_remainingPrincipal.toStringAsFixed(2)}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.attach_money, color: Colors.green[700]),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _principalDaysController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Interest Days After Reduction (optional)',
              hintText: 'e.g., 10, 60, 200 (0 means skip)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.calendar_today, color: Colors.green[700]),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final amount =
                    double.tryParse(_principalOnlyController.text) ?? 0.0;
                if (amount <= 0) {
                  _showErrorSnackbar('Please enter a valid amount');
                  return;
                }
                if (amount > _remainingPrincipal) {
                  _showErrorSnackbar(
                    'Amount cannot exceed remaining principal',
                  );
                  return;
                }
                final days = int.tryParse(_principalDaysController.text) ?? 0;
                _showConfirmationDialog('principal', amount, days: days);
              },
              icon: const Icon(Icons.account_balance),
              label: const Text('Pay Principal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Overall Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pay any amount now. It will go to interest first, then reduce principal.',
            style: TextStyle(color: Colors.blue[800], fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: 'Payment Amount (NPR)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.attach_money, color: Colors.blue[700]),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) {
              setState(() {
                _overallPaymentAmount = double.tryParse(v) ?? 0.0;
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_overallPaymentAmount <= 0) {
                  _showErrorSnackbar('Please enter a valid amount');
                  return;
                }
                _showConfirmationDialog('overall', _overallPaymentAmount);
              },
              icon: const Icon(Icons.payments),
              label: const Text('Pay Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Text(
                'Give Additional Loan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Increase principal for this loan now (same collateral).',
            style: TextStyle(color: Colors.purple[800], fontSize: 12),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final controller = TextEditingController();
              return Column(
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Additional Loan Amount (NPR)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: Colors.purple[700],
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final amount = double.tryParse(controller.text) ?? 0.0;
                        if (amount <= 0) {
                          _showErrorSnackbar('Please enter a valid amount');
                          return;
                        }
                        _showConfirmationDialog('topup', amount);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Top-up Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(
                'Confirm Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Type: ${_getPaymentTypeLabel()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Amount: NPR ${_confirmationAmount.toStringAsFixed(2)}'),
                if (_confirmationType == 'principal') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Interest days after reduction: ${_confirmationDays > 0 ? _confirmationDays : 0}',
                  ),
                ] else if (_confirmationDays > 0) ...[
                  const SizedBox(height: 4),
                  Text('Days: $_confirmationDays'),
                ],
                const SizedBox(height: 8),
                Text(
                  _getPaymentDescription(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Collection Date (BS): ${_selectedNepaliDate.format()}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              TextButton.icon(
                onPressed: _pickNepaliDate,
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _hideConfirmation,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _processPayment,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPaymentTypeLabel() {
    switch (_confirmationType) {
      case 'interest':
        return 'Interest-Only Payment';
      case 'principal':
        return 'Principal-Only Payment';
      case 'overall':
        return 'Overall Payment';
      case 'topup':
        return 'Top-up Principal';
      default:
        return 'Payment';
    }
  }

  String _getPaymentDescription() {
    switch (_confirmationType) {
      case 'interest':
        return 'Interest will be collected for $_confirmationDays days. Principal remains unchanged.';
      case 'principal':
        return 'Principal will be reduced by NPR ${_confirmationAmount.toStringAsFixed(2)}. Future interest calculated on remaining amount.';
      case 'overall':
        return 'Will be applied to interest first, then reduce principal immediately.';
      case 'topup':
        return 'Principal will increase by NPR ${_confirmationAmount.toStringAsFixed(2)}.';
      default:
        return '';
    }
  }

  Future<void> _pickNepaliDate() async {
    final initial = picker.NepaliDateTime(
      _selectedNepaliDate.year,
      _selectedNepaliDate.month,
      _selectedNepaliDate.day,
    );
    final selected = await picker.showMaterialDatePicker(
      context: context,
      initialDate: initial,
      firstDate: picker.NepaliDateTime(2000, 1, 1),
      lastDate: picker.NepaliDateTime(2200, 12, 30),
    );
    if (selected != null) {
      setState(() {
        _selectedNepaliDate = NepaliDate(
          year: selected.year,
          month: selected.month,
          day: selected.day,
        );
      });
    }
  }

  Future<void> _showCustomDayInput(BuildContext context) async {
    int selected = _selectedInterestDays;
    final controller = TextEditingController(text: selected.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Days'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Enter number of days'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text) ?? 0;
              if (v > 0) {
                setState(() {
                  _selectedInterestDays = v;
                  _updateCalculations();
                });
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _processOverallPayment() async {
    final success = await _controller.addOverallPayment(
      _confirmationAmount,
      _selectedNepaliDate.toGregorian(),
    );
    if (success) {
      _showSuccessSnackbar(
        'Payment of NPR ${_confirmationAmount.toStringAsFixed(2)} recorded',
      );
    }
  }

  Future<void> _processTopUp() async {
    final success = await _controller.addTopUp(
      _confirmationAmount,
      _selectedNepaliDate.toGregorian(),
    );
    if (success) {
      _showSuccessSnackbar(
        'Top-up of NPR ${_confirmationAmount.toStringAsFixed(2)} added',
      );
    }
  }

  Widget _buildDayButton(int days, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[700] : Colors.orange[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.orange[700]! : Colors.orange[300]!,
          ),
        ),
        child: Text(
          '$days days',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.orange[700],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationRow(
    String label,
    String value, {
    bool isResult = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: isResult ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isResult ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isResult ? Colors.black87 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
