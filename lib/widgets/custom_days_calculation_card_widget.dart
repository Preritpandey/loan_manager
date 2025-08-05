import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';

class CustomDaysCalculationCard extends StatefulWidget {
  final Loan loan;

  const CustomDaysCalculationCard({super.key, required this.loan});

  @override
  State<CustomDaysCalculationCard> createState() => _CustomDaysCalculationCardState();
}

class _CustomDaysCalculationCardState extends State<CustomDaysCalculationCard> {
  final TextEditingController _daysController = TextEditingController();
  int _customDays = 0;
  double _customInterest = 0.0;
  double _customTotal = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize with current days passed as default
    _customDays = widget.loan.daysPassed;
    _daysController.text = _customDays.toString();
    _calculateCustomInterest();
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  void _calculateCustomInterest() {
    if (_customDays > 0) {
      setState(() {
        _customInterest = widget.loan.calculateCustomDaysInterest(_customDays);
        _customTotal = widget.loan.calculateCustomDaysTotal(_customDays);
      });
    }
  }

  void _onDaysChanged(String value) {
    final days = int.tryParse(value) ?? 0;
    if (days >= 0) {
      _customDays = days;
      _calculateCustomInterest();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Custom Days Interest Calculator',
      titleIcon: Icons.calculate,
      titleColor: Colors.indigo[700],
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculate interest for any number of days',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              
              // Days input field
              TextFormField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Number of Days',
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.indigo[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.indigo[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.indigo[700]!, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _onDaysChanged,
              ),
              
              const SizedBox(height: 16),
              
              // Calculation breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculation Breakdown:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCalculationRow('Principal Amount', 'NPR ${widget.loan.amountGiven.toStringAsFixed(2)}'),
                    _buildCalculationRow('Annual Interest Rate', '${widget.loan.interestRate}%'),
                    _buildCalculationRow('Daily Interest Rate', '${widget.loan.dailyInterestRate.toStringAsFixed(4)}%'),
                    _buildCalculationRow('Number of Days', '$_customDays days'),
                    const Divider(height: 16),
                    _buildCalculationRow('Interest Calculation', 
                      '(${widget.loan.amountGiven.toStringAsFixed(2)} × ${widget.loan.dailyInterestRate.toStringAsFixed(4)}% × $_customDays) ÷ 100',
                      isFormula: true),
                    const SizedBox(height: 4),
                    _buildCalculationRow('Interest Amount', 'NPR ${_customInterest.toStringAsFixed(2)}', 
                      isResult: true, color: Colors.orange[700]),
                    _buildCalculationRow('Total Amount', 'NPR ${_customTotal.toStringAsFixed(2)}', 
                      isResult: true, color: Colors.indigo[700]),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Quick day buttons
              Text(
                'Quick Select:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo[700],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildQuickDayButton(30),
                  _buildQuickDayButton(60),
                  _buildQuickDayButton(90),
                  _buildQuickDayButton(180),
                  _buildQuickDayButton(365),
                  _buildQuickDayButton(widget.loan.daysPassed, label: 'Current'),
                  _buildQuickDayButton(widget.loan.duration, label: 'Agreed'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationRow(String label, String value, {bool isFormula = false, bool isResult = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: isFormula ? 1 : 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isFormula ? 10 : 11,
                color: Colors.grey[600],
                fontWeight: isResult ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: isFormula ? 2 : 2,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isFormula ? 10 : 11,
                fontStyle: isFormula ? FontStyle.italic : FontStyle.normal,
                fontWeight: isResult ? FontWeight.bold : FontWeight.normal,
                color: color ?? (isResult ? Colors.indigo[700] : Colors.black87),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDayButton(int days, {String? label}) {
    final isSelected = _customDays == days;
    return GestureDetector(
      onTap: () {
        setState(() {
          _customDays = days;
          _daysController.text = days.toString();
          _calculateCustomInterest();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo[700] : Colors.indigo[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.indigo[700]! : Colors.indigo[300]!,
          ),
        ),
        child: Text(
          label ?? '$days days',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.indigo[700],
          ),
        ),
      ),
    );
  }
}