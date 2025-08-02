import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';

class UpdateReceivedAmountCard extends StatelessWidget {
  final Loan loan;
  final TextEditingController controller;
  final bool isProcessing;
  final VoidCallback onUpdate;

  const UpdateReceivedAmountCard({
    super.key,
    required this.loan,
    required this.controller,
    required this.isProcessing,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Update Received Amount',
      titleIcon: Icons.edit,
      titleColor: Colors.green[700],
      children: [
        TextField(
          controller: controller,
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
            onPressed: isProcessing ? null : onUpdate,
            icon: isProcessing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.update),
            label: Text(isProcessing ? 'Updating...' : 'Update Amount'),
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
}
