import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_detail_operations_controller.dart';
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
        GetBuilder<LoanDetailOperationsController>(
          builder: (ops) {
            final overrideActive = ops.isDurationOverrideActive;
            final overrideInterest = ops.overrideInterest;
            final overrideTotal = ops.overrideOutstandingNow;
            final plannedDue = overrideActive
                ? ops.overrideOutstandingNow
                : loan.dueAmount;
            final currentInterest = loan.currentCalculatedInterest;
            final currentTotal = loan.dueAmount;
            return Column(
              children: [
                InfoRow(
                  label: 'Current Principal',
                  value: 'NPR ${loan.remainingPrincipal.toStringAsFixed(2)}',
                  color: Colors.blue[700],
                  icon: Icons.attach_money,
                  isAmount: true,
                ),
                InfoRow(
                  label: overrideActive
                      ? 'Total Interest (override)'
                      : 'Total Interest (as of today)',
                  value:
                      'NPR ${(overrideActive ? overrideInterest : currentInterest).toStringAsFixed(2)}',
                  color: Colors.orange[700],
                  icon: Icons.trending_up,
                  isAmount: true,
                ),
                InfoRow(
                  label: overrideActive
                      ? 'Total Amount (P + I for override days)'
                      : 'Total Amount (P + I as of today)',
                  value:
                      'NPR ${(overrideActive ? overrideTotal : currentTotal).toStringAsFixed(2)}',
                  color: Colors.blue[900],
                  icon: Icons.summarize,
                  isAmount: true,
                ),
                InfoRow(
                  label: 'Total Due',
                  value: 'NPR ${plannedDue.toStringAsFixed(2)}',
                  color: Colors.blue[800],
                  icon: Icons.request_quote,
                  isAmount: true,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        // Container(
        //   padding: const EdgeInsets.all(12),
        //   decoration: BoxDecoration(
        //     color: Colors.blue[50],
        //     borderRadius: BorderRadius.circular(8),
        //     border: Border.all(color: Colors.blue[200]!),
        //   ),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Text(
        //         'Interest Calculation:',
        //         style: TextStyle(
        //           fontWeight: FontWeight.bold,
        //           color: Colors.blue[700],
        //           fontSize: 12,
        //         ),
        //       ),
        //       const SizedBox(height: 4),
        //       Text(
        //         'Principal: NPR ${loan.amountGiven.toStringAsFixed(2)}',
        //         style: const TextStyle(fontSize: 11),
        //       ),
        //       Text(
        //         'Daily Rate: ${loan.dailyInterestRate.toStringAsFixed(4)}% (${loan.interestRate}% / 365)',
        //         style: const TextStyle(fontSize: 11),
        //       ),
        //       GetBuilder<LoanDetailOperationsController>(
        //         builder: (ops) {
        //           final overrideActive = ops.isDurationOverrideActive;
        //           final days = overrideActive
        //               ? (ops.overrideDays ?? 0)
        //               : (loan.daysPassed < 30 ? 30 : loan.daysPassed);
        //           return Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: [
        //               Text('Days: $days', style: const TextStyle(fontSize: 11)),
        //               Text(
        //                 'Interest = (${loan.amountGiven.toStringAsFixed(2)} × ${loan.dailyInterestRate.toStringAsFixed(4)}% × $days) / 100',
        //                 style: const TextStyle(
        //                   fontSize: 11,
        //                   fontStyle: FontStyle.italic,
        //                 ),
        //               ),
        //             ],
        //           );
        //         },
        //       ),
        //     ],
        //   ),
        // ),

        // Real-time due (as of today) is intentionally omitted to prevent confusion.
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
        GetBuilder<LoanDetailOperationsController>(
          builder: (ops) {
            final overrideActive = ops.isDurationOverrideActive;
            final amount = overrideActive
                ? ops.overrideOutstandingNow
                : loan.dueAmount;
            return InfoRow(
              label: 'Amount Due',
              value: 'NPR ${amount.toStringAsFixed(2)}',
              color: amount > 0 ? Colors.red[700] : Colors.green[700],
              icon: Icons.account_balance,
              isAmount: true,
            );
          },
        ),
      ],
    );
  }
}
