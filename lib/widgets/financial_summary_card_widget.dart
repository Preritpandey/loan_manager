import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';
import 'package:list/widgets/info_row_widget.dart';

class FinancialSummaryCard extends StatelessWidget {
  final Loan loan;

  const FinancialSummaryCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Financial Summary',
      titleIcon: Icons.account_balance_wallet,
      titleColor: Colors.purple[700],
      children: [
        InfoRow(
          label: 'Principal Amount',
          value: 'NPR ${loan.amountGiven.toStringAsFixed(2)}',
          color: Colors.blue[700],
          icon: Icons.attach_money,
          isAmount: true,
        ),
        InfoRow(
          label: 'Full Interest',
          value: 'NPR ${loan.agreedPeriodInterest.toStringAsFixed(2)}',
          color: Colors.orange[700],
          icon: Icons.trending_up,
          isAmount: true,
        ),
        InfoRow(
          label: 'Total Due (P+I)',
          value: 'NPR ${loan.immediateTotalDue.toStringAsFixed(2)}',
          color: Colors.blue[700],
          icon: Icons.calculate,
          isAmount: true,
        ),

        if (loan.isOverdue) ...[
          const Divider(height: 20),
          InfoRow(
            label: 'Overdue Interest',
            value: 'NPR ${loan.overdueInterest.toStringAsFixed(2)}',
            color: Colors.red[700],
            icon: Icons.warning,
            isAmount: true,
          ),
          InfoRow(
            label: 'Total Interest',
            value: 'NPR ${loan.currentInterest.toStringAsFixed(2)}',
            color: Colors.orange[700],
            icon: Icons.trending_up,
            isAmount: true,
          ),
        ],

        const Divider(height: 20),
        InfoRow(
          label: 'Amount Received',
          value: 'NPR ${loan.amountReceived.toStringAsFixed(2)}',
          color: Colors.green[700],
          icon: Icons.payment,
          isAmount: true,
        ),
        InfoRow(
          label: 'Amount Due',
          value: 'NPR ${loan.dueAmount.toStringAsFixed(2)}',
          color: loan.dueAmount > 0 ? Colors.red[700] : Colors.green[700],
          icon: Icons.account_balance,
          isAmount: true,
        ),
      ],
    );
  }
}
