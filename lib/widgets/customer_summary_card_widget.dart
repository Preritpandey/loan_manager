import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';

class CustomerSummaryCard extends StatelessWidget {
  final Loan loan;

  const CustomerSummaryCard({super.key, required this.loan});

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LoanController loanController = Get.find<LoanController>();
    final customerLoans = loanController.getLoansByCustomerName(loan.name);
    final totalDueAmount = customerLoans.fold(
      0.0,
      (sum, l) => sum + l.plannedDue,
    );
    final totalAmountGiven = customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.amountGiven,
    );
    final totalAmountReceived = customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.amountReceived,
    );
    final isOverdue = loanController.isCustomerOverdue(loan.name);
    final totalOverdueDays = loanController.getTotalOverdueDaysForCustomer(
      loan.name,
    );

    return InfoCard(
      title: 'Customer Summary - ${loan.name}',
      titleIcon: Icons.person_pin,
      titleColor: Colors.indigo[700],
      children: [
        if (isOverdue)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customer has overdue loans! Total overdue: $totalOverdueDays days',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Total Loans',
                customerLoans.length.toString(),
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryItem(
                'Total Given',
                'NPR ${totalAmountGiven.toStringAsFixed(0)}',
                Icons.trending_up,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Total Received',
                'NPR ${totalAmountReceived.toStringAsFixed(0)}',
                Icons.payment,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryItem(
                'Total Due',
                'NPR ${totalDueAmount.toStringAsFixed(0)}',
                Icons.account_balance,
                totalDueAmount > 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),

        // Removed per requirement: do not display the list of all other loans of the same customer on loan details page
      ],
    );
  }
}
