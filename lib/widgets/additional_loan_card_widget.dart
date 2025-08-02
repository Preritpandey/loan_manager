import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/add_additional_loan_page.dart';
import 'package:list/widgets/info_card_widget.dart';

class AdditionalLoanCard extends StatelessWidget {
  final Loan loan;

  const AdditionalLoanCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
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
                Get.to(() => AddAdditionalLoanPage(existingLoan: loan)),
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
}
