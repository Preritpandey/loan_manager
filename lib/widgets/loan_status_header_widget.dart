import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_detail_operations_controller.dart';
import 'package:list/widgets/status_badge_widget.dart';

class LoanStatusHeader extends StatelessWidget {
  final Loan loan;

  const LoanStatusHeader({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 204, 21, 27),
            Color.fromARGB(255, 224, 1, 76),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NPR ${loan.amountGiven.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Principal Amount',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GetBuilder<LoanDetailOperationsController>(
                  builder: (ops) {
                    final bool overrideActive = ops.isDurationOverrideActive;
                    final double amount = overrideActive
                        ? ops.overrideOutstandingNow
                        : loan.dueAmount;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'NPR ${amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: amount > 0
                                ? Colors.red[100]
                                : Colors.green[100],
                            fontSize: isMobile ? 18 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Amount Due',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (loan.isFullyPaid)
                StatusBadge(
                  text: 'FULLY PAID',
                  color: Colors.green[100]!,
                  icon: Icons.check_circle,
                ),
              StatusBadge(
                text: '${loan.interestRate} YEARLY',
                color: Colors.purple[100]!,
                icon: Icons.percent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
