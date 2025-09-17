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

        if (customerLoans.length > 1) ...[
          const SizedBox(height: 20),
          const Divider(),
          Row(
            children: [
              Icon(Icons.list, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'All Loans (${customerLoans.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...customerLoans
              .map(
                (loan) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: loan.serialNumber == this.loan.serialNumber
                        ? Colors.blue[50]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: loan.serialNumber == this.loan.serialNumber
                          ? Colors.blue[300]!
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${loan.type} - ${loan.jewelleryName}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (loan.serialNumber == this.loan.serialNumber)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'CURRENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${loan.interestRate}% • ${loan.duration} days • ${loan.serialNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'NPR ${loan.amountGiven.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (loan.isOverdue) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${loan.overdueDays}d',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
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
