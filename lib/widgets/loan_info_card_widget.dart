import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_detail_operations_controller.dart';
import 'package:list/controllers/loan_controller.dart';
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

  Future<void> _showRateEditDialog() async {
    final controller = Get.find<LoanController>();
    final rateController = TextEditingController(
      text: widget.loan.interestRate.toStringAsFixed(2),
    );
    var effectiveDate = DateTime.now();
    InterestRateChangePreview? preview;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updatePreview() {
              final newRate = double.tryParse(rateController.text.trim());
              if (newRate == null || newRate <= 0) {
                setDialogState(() => preview = null);
                return;
              }
              setDialogState(() {
                preview = widget.loan.previewInterestRateChange(
                  newRate,
                  effectiveDate,
                );
              });
            }

            return AlertDialog(
              title: const Text('Edit Annual Interest Rate'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current rate: ${widget.loan.interestRate}%'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'New annual rate (%)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => updatePreview(),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: effectiveDate,
                          firstDate: widget.loan.date,
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          effectiveDate = picked;
                          updatePreview();
                        }
                      },
                      icon: const Icon(Icons.event),
                      label: Text('Effective: ${_formatDate(effectiveDate)}'),
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        preview!.isIncrease
                            ? 'Interest rate increase'
                            : 'Interest rate discount',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Previous due: NPR ${preview!.previousCalculatedDue.toStringAsFixed(2)}',
                      ),
                      Text('Affected periods: ${preview!.affectedPeriodsLabel}'),
                      Text(
                        'Recalculated due: NPR ${preview!.recalculatedDue.toStringAsFixed(2)}',
                      ),
                      Text(
                        '${preview!.isIncrease ? 'Additional interest' : 'Interest discount'}: '
                        'NPR ${preview!.adjustmentAmount.abs().toStringAsFixed(2)}',
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newRate = double.tryParse(
                      rateController.text.trim(),
                    );
                    if (newRate == null || newRate <= 0) return;
                    final change = controller.changeInterestRate(
                      widget.loan.serialNumber,
                      newRate,
                      effectiveDate,
                    );
                    if (change != null && mounted) {
                      Get.find<LoanDetailOperationsController>().refreshLoan();
                      setState(() {});
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    rateController.dispose();
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
        // Duration editing removed
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.percent, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width < 600 ? 100 : 140,
                child: Text(
                  'Annual Interest Rate',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                    fontSize: MediaQuery.of(context).size.width < 600
                        ? 12
                        : 14,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${widget.loan.interestRate}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit interest rate',
                onPressed: _showRateEditDialog,
                icon: const Icon(Icons.edit, size: 18),
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
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
