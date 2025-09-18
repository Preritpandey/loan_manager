import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';
import 'package:list/widgets/info_row_widget.dart';
import 'package:list/utils/nepali_date_utils.dart';

class LoanInfoCard extends StatefulWidget {
  final Loan loan;

  const LoanInfoCard({super.key, required this.loan});

  @override
  State<LoanInfoCard> createState() => _LoanInfoCardState();
}

class _LoanInfoCardState extends State<LoanInfoCard> {
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatNepaliDate(NepaliDate nepaliDate) {
    return nepaliDate.format();
  }

  // Removed duration editing UI per new requirement

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Loan Information',
      titleIcon: Icons.receipt_long,
      titleColor: Colors.green[700],
      children: [
        InfoRow(
          label: 'Loan Date (Nepali)',
          value: _formatNepaliDate(widget.loan.nepaliDate),
          icon: Icons.calendar_today,
        ),
        InfoRow(
          label: 'Loan Date (Gregorian)',
          value: _formatDate(widget.loan.date),
          icon: Icons.calendar_today,
        ),
        // Duration editing removed
        InfoRow(
          label: 'Annual Interest Rate',
          value: '${widget.loan.interestRate}%',
          icon: Icons.percent,
        ),
        InfoRow(
          label: 'Daily Interest Rate',
          value: '${widget.loan.dailyInterestRate.toStringAsFixed(4)}%',
          icon: Icons.percent,
          color: Colors.blue[600],
        ),
        InfoRow(
          label: 'Due Date',
          value: _formatDate(
            widget.loan.date.add(Duration(days: widget.loan.duration)),
          ),
          icon: Icons.event,
        ),
        InfoRow(
          label: 'Days Passed',
          value: '${widget.loan.daysPassed} days',
          icon: Icons.timelapse,
        ),
        if (widget.loan.isOverdue)
          InfoRow(
            label: 'Overdue Days',
            value: '${widget.loan.overdueDays} days',
            color: Colors.red,
            icon: Icons.warning,
          )
        else
          InfoRow(
            label: 'Days Remaining',
            value: '${widget.loan.daysRemaining} days',
            color: widget.loan.daysRemaining > 0 ? Colors.green : Colors.red,
            icon: Icons.schedule,
          ),
      ],
    );
  }
}
