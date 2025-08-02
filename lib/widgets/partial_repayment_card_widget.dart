import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';

class PartialRepaymentCard extends StatelessWidget {
  final Loan loan;
  final TextEditingController controller;
  final bool isProcessing;
  final VoidCallback onAddRepayment;
  final List<PartialRepayment> partialRepayments;

  const PartialRepaymentCard({
    super.key,
    required this.loan,
    required this.controller,
    required this.isProcessing,
    required this.onAddRepayment,
    required this.partialRepayments,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
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
                'Current Balance: NPR ${loan.currentBalance.toStringAsFixed(2)}',
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
          controller: controller,
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
                    firstDate: loan.date,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != DateTime.now()) {
                    // Handle date selection if needed
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
            onPressed: isProcessing ? null : onAddRepayment,
            icon: isProcessing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline),
            label: Text(isProcessing ? 'Processing...' : 'Add Repayment'),
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
}
