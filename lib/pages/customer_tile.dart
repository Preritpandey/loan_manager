import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/customer_loans_page.dart';

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
    final isOverdue = controller.isCustomerOverdue(customerName);

    // Aggregates for this customer
    // Use remainingPrincipal instead of amountGiven to reflect the actual outstanding principal
    final totalGiven = customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.amountGiven,
    );

    /**
       final totalAmountGiven = customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.amountGiven,
    );
     */

    final totalDue = customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.dueAmount,
    );

    // Theme color (requested red)
    final themeRed = const Color.fromARGB(255, 204, 21, 27);
    final baseColor = themeRed;

    // Responsiveness
    final width = MediaQuery.of(context).size.width;
    final isDesktopLike = width > 768 || GetPlatform.isDesktop;

    final double titleSize = isDesktopLike ? 18 : 16;
    final double subTextSize = isDesktopLike ? 12 : 11;
    final double tilePadding = isDesktopLike ? 16 : 12;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _showCustomerDetails(),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(tilePadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                baseColor.withOpacity(0.03),
                baseColor.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: baseColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Customer Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person,
                      color: baseColor,
                      size: isDesktopLike ? 28 : 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name and loan count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w600,
                            color: baseColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.assignment,
                              size: isDesktopLike ? 14 : 12,
                              color: baseColor.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${customerLoans.length} loan${customerLoans.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: subTextSize,
                                color: baseColor.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status / Chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'OVERDUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.chevron_right,
                        color: baseColor,
                        size: isDesktopLike ? 24 : 20,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Totals row (icons removed per request)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'Total Given',
                      value: 'NPR ${totalGiven.toStringAsFixed(2)}',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      label: 'Total Due',
                      value: 'NPR ${totalDue.toStringAsFixed(2)}',
                      color: totalDue > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isDesktopLike = width > 768 || GetPlatform.isDesktop;
    final double cardPadding = isDesktopLike ? 12 : 10;
    final double labelSize = isDesktopLike ? 11 : 10;
    final double valueSize = isDesktopLike ? 14 : 13;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails() {
    // Navigate to customer loans page showing all loans for this customer
    Get.to(
      () => CustomerLoansPage(
        customerName: customerName,
        customerLoans: customerLoans,
      ),
    );
  }
}
