import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';
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
          colors: [Colors.blue[700]!, Colors.blue[500]!],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'NPR ${loan.dueAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: loan.dueAmount > 0
                            ? Colors.red[300]
                            : Colors.green[300],
                        fontSize: isMobile ? 18 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Amount Due',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
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
                  color: Colors.green[300]!,
                  icon: Icons.check_circle,
                )
              else if (loan.isOverdue)
                StatusBadge(
                  text: '${loan.overdueDays} DAYS OVERDUE',
                  color: Colors.red[300]!,
                  icon: Icons.warning,
                )
              else
                StatusBadge(
                  text: '${loan.daysRemaining} DAYS LEFT',
                  color: Colors.orange[300]!,
                  icon: Icons.schedule,
                ),
              StatusBadge(
                text: '${loan.interestRate}% DAILY',
                color: Colors.purple[300]!,
                icon: Icons.percent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
