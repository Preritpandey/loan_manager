import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';

class LoanTile extends StatelessWidget {
  final Loan loan;

  const LoanTile({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(loan.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Interest: NPR ${loan.acquiredInterest.toStringAsFixed(2)}'),
            Text('Received: NPR ${loan.amountReceived.toStringAsFixed(2)}'),
            Text('Type: ${loan.type} - ${loan.jewelleryName}'),
            Text('Serial: ${loan.serialNumber}'),
          ],
        ),
      ),
    );
  }
}
