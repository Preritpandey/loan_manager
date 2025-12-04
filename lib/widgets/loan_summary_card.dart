import 'package:flutter/material.dart';

class LoanSummaryCard extends StatelessWidget {
  final EdgeInsets padding;
  final bool isDesktop;
  final int totalLoans;
  final double totalDue;
  final int overdueLoans;
  final double totalReceived;
  final double totalPrincipalDue;
  final double totalInterestDue;
  final VoidCallback? onOverdueTap;

  // Add a unique key for this widget to help with updates
  final String refreshKey =
      'loan_summary_${DateTime.now().millisecondsSinceEpoch}';

  LoanSummaryCard({
    super.key,
    required this.padding,
    required this.isDesktop,
    required this.totalLoans,
    required this.totalDue,
    required this.overdueLoans,
    required this.totalReceived,
    required this.totalPrincipalDue,
    required this.totalInterestDue,
    this.onOverdueTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: padding,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loan Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      title: 'Total Loans',
                      value: '$totalLoans',
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with icon and title
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Total Due',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Total amount
                          Text(
                            'NPR ${totalDue.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Divider line
                          Container(
                            height: 1,
                            color: Colors.red.withOpacity(0.2),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          // Breakdown
                          _buildDetailRow(
                            'Principal Due',
                            totalPrincipalDue,
                            Colors.grey[800]!,
                          ),
                          const SizedBox(height: 2),
                          _buildDetailRow(
                            'Interest Due',
                            totalInterestDue,
                            Colors.orange[700]!,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onOverdueTap,
                      child: _SummaryItem(
                        title: 'Overdue',
                        value: '$overdueLoans',
                        icon: Icons.warning,
                        color: Colors.orange,
                        isClickable: onOverdueTap != null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryItem(
                      title: 'Received',
                      value: 'NPR ${totalReceived.toStringAsFixed(0)}',
                      icon: Icons.payment,
                      color: Colors.green,
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

  Widget _buildDetailRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
          Text(
            'NPR ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isClickable;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: isClickable
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
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
                  title,
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
}
