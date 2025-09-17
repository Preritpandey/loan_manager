import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';
import 'package:list/widgets/info_row_widget.dart';
import 'package:list/utils/nepali_date_utils.dart';
import 'package:list/controllers/loan_detail_operations_controller.dart';
import 'package:list/controllers/loan_controller.dart';

class LoanInfoCard extends StatefulWidget {
  final Loan loan;

  const LoanInfoCard({super.key, required this.loan});

  @override
  State<LoanInfoCard> createState() => _LoanInfoCardState();
}

class _LoanInfoCardState extends State<LoanInfoCard> {
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
      text: widget.loan.duration.toString(),
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatNepaliDate(NepaliDate nepaliDate) {
    return nepaliDate.format();
  }

  void _saveDuration() {
    final v = int.tryParse(_durationController.text.trim());
    if (v == null || v <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid duration in days')),
      );
      return;
    }
    if (v == widget.loan.duration) return;
    widget.loan.duration = v;
    if (widget.loan.isInBox) {
      widget.loan.save();
    }
    // Ensure all dependent summaries recompute and UI refreshes beyond this card
    try {
      // Refresh calculations in the loan list/controller layer
      Get.find<LoanController>().refreshLoanCalculations();
    } catch (_) {}
    try {
      // Force the loan detail page to rebuild (GetBuilder)
      Get.find<LoanDetailOperationsController>().update();
    } catch (_) {}
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Duration updated')));
  }

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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              const SizedBox(
                width: 120,
                child: Text(
                  'Duration',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF616161),
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          hintText: 'days',

                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveDuration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
