import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/loan_detail_page.dart';
import 'package:list/controllers/loan_controller.dart';

class LoanTile extends StatelessWidget {
  final Loan loan;

  const LoanTile({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoanController>();
    final customerLoans = controller.getLoansByCustomerName(loan.name);
    final totalDueAmount = controller.getTotalDueAmountForCustomer(loan.name);
    final hasMultipleLoans = customerLoans.length > 1;

    return Card(
      child: InkWell(
        onTap: () => Get.to(() => LoanDetailPage(loan: loan))?.then((_) {
          // Refresh the loans list when returning from detail page
          final controller = Get.find<LoanController>();
          controller.refreshLoans();
        }),
        child: ListTile(
          title: Row(
            children: [
              Expanded(child: Text(loan.name)),
              if (hasMultipleLoans)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${customerLoans.length} loans',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Interest: NPR ${loan.acquiredInterest.toStringAsFixed(2)}'),
              Text('Received: NPR ${loan.amountReceived.toStringAsFixed(2)}'),
              Text(
                'Due Amount: NPR ${loan.dueAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: loan.dueAmount > 0 ? Colors.red : Colors.green,
                ),
              ),
              if (hasMultipleLoans) ...[
                const SizedBox(height: 4),
                Text(
                  'Total Due: NPR ${totalDueAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: totalDueAmount > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
              Text('Type: ${loan.type} - ${loan.jewelleryName}'),
              Text('Serial: ${loan.serialNumber}'),
            ],
          ),
        ),
      ),
    );
  }
}
