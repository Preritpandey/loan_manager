import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';
import 'package:list/widgets/info_row_widget.dart';

class LoanInfoCard extends StatelessWidget {
  final Loan loan;

  const LoanInfoCard({super.key, required this.loan});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Loan Information',
      titleIcon: Icons.receipt_long,
      titleColor: Colors.green[700],
      children: [
        InfoRow(
          label: 'Loan Date',
          value: _formatDate(loan.date),
          icon: Icons.calendar_today,
        ),
        InfoRow(
          label: 'Duration',
          value: '${loan.duration} days',
          icon: Icons.schedule,
        ),
        InfoRow(
          label: 'Annual Interest Rate',
          value: '${loan.interestRate}%',
          icon: Icons.percent,
        ),
        InfoRow(
          label: 'Daily Interest Rate',
          value: '${loan.dailyInterestRate.toStringAsFixed(4)}%',
          icon: Icons.percent,
          color: Colors.blue[600],
        ),
        InfoRow(
          label: 'Due Date',
          value: _formatDate(loan.date.add(Duration(days: loan.duration))),
          icon: Icons.event,
        ),
        InfoRow(
          label: 'Days Passed',
          value: '${loan.daysPassed} days',
          icon: Icons.timelapse,
        ),
        if (loan.isOverdue)
          InfoRow(
            label: 'Overdue Days',
            value: '${loan.overdueDays} days',
            color: Colors.red,
            icon: Icons.warning,
          )
        else
          InfoRow(
            label: 'Days Remaining',
            value: '${loan.daysRemaining} days',
            color: loan.daysRemaining > 0 ? Colors.green : Colors.red,
            icon: Icons.schedule,
          ),
      ],
    );
  }
}
