import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/loan_detail_page.dart';

class CustomerTile extends StatelessWidget {
  final String customerName;
  final List<Loan> customerLoans;

  const CustomerTile({
    super.key,
    required this.customerName,
    required this.customerLoans,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoanController>();
    final totalDueAmount = controller.getTotalDueAmountForCustomer(
      customerName,
    );
    final totalAmountGiven = customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.amountGiven,
    );
    final totalAmountReceived = customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.amountReceived,
    );
    final totalFixedInterest = customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.agreedPeriodInterest,
    );
    final totalOverdueInterest = controller.getTotalOverdueInterestForCustomer(
      customerName,
    );
    final isOverdue = controller.isCustomerOverdue(customerName);
    final totalOverdueDays = controller.getTotalOverdueDaysForCustomer(
      customerName,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _showCustomerDetails(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Name and Loan Count
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${customerLoans.length} loan${customerLoans.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Financial Summary
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Given',
                      'NPR ${totalAmountGiven.toStringAsFixed(2)}',
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Received',
                      'NPR ${totalAmountReceived.toStringAsFixed(2)}',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Fixed Interest',
                      'NPR ${totalFixedInterest.toStringAsFixed(2)}',
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Due',
                      'NPR ${totalDueAmount.toStringAsFixed(2)}',
                      totalDueAmount > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              if (isOverdue) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Overdue Days',
                        '$totalOverdueDays days',
                        Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Overdue Interest',
                        'NPR ${totalOverdueInterest.toStringAsFixed(2)}',
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // Loan Details
              const Text(
                'Loans:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              ...customerLoans
                  .map(
                    (loan) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${loan.type} - ${loan.jewelleryName}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '${loan.interestRate}% - ${loan.duration} days',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'NPR ${loan.immediateTotalDue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (loan.isOverdue)
                                Text(
                                  '${loan.overdueDays} days overdue',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),

              // Customer Info
              const SizedBox(height: 12),
              Text(
                'Phone: ${customerLoans.first.phone}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showCustomerDetails() {
    // Show the first loan's detail page (user can navigate to others from there)
    Get.to(() => LoanDetailPage(loan: customerLoans.first));
  }
}
