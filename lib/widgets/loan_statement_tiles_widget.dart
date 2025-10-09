import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/controllers/loan_detail_operations_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/utils/nepali_date_utils.dart';

class LoanStatementTiles extends StatelessWidget {
  final Loan loan;
  const LoanStatementTiles({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoanController>();

    final amountPaid = loan.amountReceived;
    final ops = Get.find<LoanDetailOperationsController>();
    final bool overrideActive = ops.isDurationOverrideActive;
    final outstanding = overrideActive
        ? ops.overrideOutstandingNow
        : loan.dueAmount;

    final tiles = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        // Compute additional/top-up statistics from negative partial repayments
        final int additionalCount = loan.partialRepayments.where((r) => r.amount < 0).length;
        final double additionalTotal = loan.partialRepayments
            .where((r) => r.amount < 0)
            .fold(0.0, (sum, r) => sum + (-r.amount));

        final children = [
          _Tile(
            color: Colors.green.shade50,
            border: Colors.green.shade300,
            iconColor: Colors.green.shade700,
            icon: Icons.payments,
            title: 'Amount Paid',
            value: 'NPR ${amountPaid.toStringAsFixed(2)}',
            subtitle: 'Total received from borrower',
          ),
          _Tile(
            color: Colors.orange.shade50,
            border: Colors.orange.shade300,
            iconColor: Colors.orange.shade700,
            icon: Icons.add_card,
            title: 'Additional Loans',
            value: additionalCount == 0
                ? 'None'
                : '$additionalCount loan${additionalCount > 1 ? 's' : ''}',
            subtitle: additionalCount == 0
                ? 'No extra disbursements'
                : 'Total Given: NPR ${additionalTotal.toStringAsFixed(2)}',
          ),
          _Tile(
            color: Colors.blue.shade50,
            border: Colors.blue.shade300,
            iconColor: Colors.blue.shade700,
            icon: Icons.account_balance_wallet,
            title: 'Outstanding',
            value: 'NPR ${outstanding.toStringAsFixed(2)}',
            subtitle: 'Principal + Interest as of now',
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              // Expanded(child: children[0]),
              // const SizedBox(width: 12),
              // Expanded(child: children[1]),
              // const SizedBox(width: 12),
              // Expanded(child: children[2]),
            ],
          );
        }
        return Column(
          children: [
            // children[0],
            // const SizedBox(height: 12),
            // children[1],
            // const SizedBox(height: 12),
            // children[2],
          ],
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tiles,
        const SizedBox(height: 12),
        _StatementSection(loan: loan),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final Color color;
  final Color border;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _Tile({
    required this.color,
    required this.border,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementSection extends StatefulWidget {
  final Loan loan;
  const _StatementSection({required this.loan});

  @override
  State<_StatementSection> createState() => _StatementSectionState();
}

class _StatementSectionState extends State<_StatementSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoanController>();

    final eventsAsc = _buildEvents(widget.loan);
    final eventsDesc = List<_StatementEvent>.from(eventsAsc.reversed);
    final List<_StatementEvent> displayedEvents = _showAll
        ? eventsAsc
        : eventsDesc.take(2).toList();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Statement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (eventsAsc.isEmpty)
            Text(
              'No transactions yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: displayedEvents
                  .map((e) => _StatementRow(event: e))
                  .toList(),
            ),
          if (eventsAsc.length > 2) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _showAll = !_showAll),
                icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more),
                label: Text(_showAll ? 'Show less' : 'Show more'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_StatementEvent> _buildEvents(Loan loan) {
    final List<_StatementEvent> events = [];

    // Initial disbursement
    events.add(
      _StatementEvent(
        date: loan.date,
        type: _EventType.disbursement,
        amount: loan.amountGiven,
      ),
    );

    // Build repayment breakdowns sequentially
    double principal = loan.amountGiven;
    double accrued = 0.0; // interest accrued but not yet paid
    final dailyRate = loan.dailyInterestRate;

    final repayments = List<PartialRepayment>.from(loan.partialRepayments)
      ..sort((a, b) => a.date.compareTo(b.date));

    DateTime lastDate = loan.date;

    for (final r in repayments) {
      final days = r.date.difference(lastDate).inDays;
      if (days > 0 && principal > 0) {
        accrued += (principal * dailyRate * days) / 100.0;
      }

      // Handle top-ups (negative amounts) differently
      if (r.amount < 0) {
        // This is a top-up (additional disbursement)
        events.add(
          _StatementEvent(
            date: r.date,
            type: _EventType.topUp,
            amount: -r.amount, // Make it positive for display
            note: 'Additional loan amount',
          ),
        );
        principal += (-r.amount); // Increase principal
        lastDate = r.date;
        continue;
      }

      // Handle regular repayments (positive amounts)
      double remaining = r.amount;
      double interestPortion = 0.0;
      double principalPortion = 0.0;
      double extraInterest = 0.0;

      // Pay accrued interest first
      if (remaining > 0) {
        final payInterest = remaining <= accrued ? remaining : accrued;
        interestPortion += payInterest;
        accrued -= payInterest;
        remaining -= payInterest;
      }

      // Then principal
      if (remaining > 0) {
        final payPrincipal = remaining >= principal ? principal : remaining;
        principalPortion += payPrincipal;
        principal -= payPrincipal;
        remaining -= payPrincipal;
      }

      // Any leftover is extra interest (beyond accrued)
      if (remaining > 0) {
        extraInterest += remaining;
        remaining = 0.0;
      }

      // Determine the specific type of repayment
      _EventType repaymentType = _EventType.repayment;
      if (principalPortion > 0 && interestPortion == 0 && extraInterest == 0) {
        repaymentType = _EventType.principalOnly;
      } else if (principalPortion == 0 &&
          interestPortion > 0 &&
          extraInterest == 0) {
        repaymentType = _EventType.interestOnly;
      } else if (principalPortion > 0 && interestPortion > 0) {
        repaymentType = _EventType.mixedPayment;
      }

      events.add(
        _StatementEvent(
          date: r.date,
          type: repaymentType,
          amount: r.amount,
          interestPortion: interestPortion,
          principalPortion: principalPortion,
          extraInterest: extraInterest,
        ),
      );

      lastDate = r.date;
    }

    // Note: Removed additional loans from statement as they should not appear
    // in individual loan statements - they are separate loans

    // Sort by date ascending
    events.sort((a, b) => a.date.compareTo(b.date));

    return events;
  }
}

class _StatementRow extends StatelessWidget {
  final _StatementEvent event;
  const _StatementRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final nepali = NepaliDate.fromGregorian(event.date).format();

    Color stripeColor;
    IconData icon;
    String title;

    switch (event.type) {
      case _EventType.disbursement:
        stripeColor = Colors.orange.shade300;
        icon = Icons.call_received; // money out (from shop)
        title = 'Loan Disbursed';
        break;
      case _EventType.repayment:
        stripeColor = Colors.green.shade400;
        icon = Icons.call_made; // money in
        title = 'Payment Received';
        break;
      case _EventType.principalOnly:
        stripeColor = Colors.blue.shade400;
        icon = Icons.account_balance_wallet;
        title = 'Principal Collected';
        break;
      case _EventType.interestOnly:
        stripeColor = Colors.amber.shade400;
        icon = Icons.percent;
        title = 'Interest Collected';
        break;
      case _EventType.mixedPayment:
        stripeColor = Colors.purple.shade400;
        icon = Icons.payments;
        title = 'Mixed Payment';
        break;
      case _EventType.topUp:
        stripeColor = Colors.teal.shade400;
        icon = Icons.add_circle;
        title = 'Top-up Added';
        break;
      case _EventType.extraLoan:
        stripeColor = Colors.blue.shade400;
        icon = Icons.add_card;
        title = 'Extra Loan Given';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: stripeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 20, color: stripeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      nepali,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip(
                      'NPR ${event.amount.toStringAsFixed(2)}',
                      Colors.black87,
                      Colors.grey.shade300,
                    ),
                    if (event.type == _EventType.repayment ||
                        event.type == _EventType.principalOnly ||
                        event.type == _EventType.interestOnly ||
                        event.type == _EventType.mixedPayment) ...[
                      if (event.principalPortion > 0)
                        _chip(
                          'Principal ${event.principalPortion.toStringAsFixed(2)}',
                          Colors.blue.shade800,
                          Colors.blue.shade100,
                        ),
                      if (event.interestPortion > 0)
                        _chip(
                          'Interest ${event.interestPortion.toStringAsFixed(2)}',
                          Colors.green.shade800,
                          Colors.green.shade100,
                        ),
                      if (event.extraInterest > 0)
                        _chip(
                          'Extra Interest ${event.extraInterest.toStringAsFixed(2)}',
                          Colors.red.shade800,
                          Colors.red.shade100,
                        ),
                    ] else if (event.type == _EventType.disbursement) ...[
                      _chip(
                        'Disbursement',
                        Colors.orange.shade800,
                        Colors.orange.shade100,
                      ),
                    ] else if (event.type == _EventType.topUp) ...[
                      _chip(
                        'Top-up',
                        Colors.teal.shade800,
                        Colors.teal.shade100,
                      ),
                    ] else if (event.type == _EventType.extraLoan) ...[
                      _chip(
                        'Extra Loan',
                        Colors.blue.shade800,
                        Colors.blue.shade100,
                      ),
                    ],
                  ],
                ),
                if (event.note != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.note!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum _EventType {
  disbursement,
  repayment,
  extraLoan,
  topUp,
  principalOnly,
  interestOnly,
  mixedPayment,
}

class _StatementEvent {
  final DateTime date;
  final _EventType type;
  final double amount;
  final double interestPortion;
  final double principalPortion;
  final double extraInterest;
  final String? note;

  _StatementEvent({
    required this.date,
    required this.type,
    required this.amount,
    this.interestPortion = 0.0,
    this.principalPortion = 0.0,
    this.extraInterest = 0.0,
    this.note,
  });
}
