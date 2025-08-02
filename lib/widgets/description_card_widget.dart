import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';

class DescriptionCard extends StatelessWidget {
  final Loan loan;

  const DescriptionCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
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
          child: Text(loan.description, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
