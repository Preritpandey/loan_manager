import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/bank_loan_controller.dart';

class BankLoansPage extends StatelessWidget {
  final BankLoanController controller = Get.find<BankLoanController>();

  BankLoansPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Deposited Loans'),
        backgroundColor: const Color.fromARGB(255, 204, 21, 27),
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (controller.bankLoans.isEmpty) {
          return const Center(
            child: Text('No loans have been deposited to the bank yet.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.bankLoans.length,
          itemBuilder: (context, index) {
            final bankLoan = controller.bankLoans[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bankLoan.originalLoan.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(bankLoan.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bankLoan.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Deposited on: ${_formatDate(bankLoan.depositDate)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn(
                          'Principal',
                          'NPR ${bankLoan.originalLoan.amountGiven.toStringAsFixed(0)}',
                        ),
                        _buildInfoColumn(
                          'Interest Rate',
                          '${bankLoan.originalLoan.interestRate}%',
                        ),
                        _buildInfoColumn(
                          'Duration',
                          '${bankLoan.originalLoan.duration} days',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'settled':
        return Colors.blue;
      case 'defaulted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
