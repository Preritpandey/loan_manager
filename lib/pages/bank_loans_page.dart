import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/bank_loan_controller.dart';

class BankLoansPage extends StatefulWidget {
  BankLoansPage({Key? key}) : super(key: key);

  @override
  State<BankLoansPage> createState() => _BankLoansPageState();
}

class _BankLoansPageState extends State<BankLoansPage> {
  final BankLoanController controller = Get.find<BankLoanController>();
  String _query = '';

  List filteredLoans() {
    if (_query.trim().isEmpty) return controller.bankLoans;
    final q = _query.toLowerCase();
    return controller.bankLoans.where((b) {
      final loan = b.originalLoan;
      return loan.name.toLowerCase().contains(q) ||
          loan.serialNumber.toLowerCase().contains(q) ||
          (loan.loanId.toLowerCase().contains(q));
    }).toList();
  }

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

        final list = filteredLoans();

        if (controller.bankLoans.isEmpty) {
          return const Center(
            child: Text('No loans have been deposited to the bank yet.'),
          );
        }

        return Column(
          children: [
            // Total Deposited Amount Card
            if (controller.bankLoans.isNotEmpty)
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Total Deposited Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'रु ${controller.totalDepositedAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 204, 21, 27),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${controller.bankLoans.length} ${controller.bankLoans.length == 1 ? 'loan' : 'loans'} deposited',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by customer name, serial number or loan ID',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            if (_query.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Results: ${list.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final bankLoan = list[index];
                  return GestureDetector(
                    onTap: () {
                      Get.toNamed(
                        '/loan-details',
                        arguments: bankLoan.originalLoan,
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bankLoan.originalLoan.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'SN: ${bankLoan.originalLoan.serialNumber}  •  ID: ${bankLoan.originalLoan.loanId}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
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
                                    IconButton(
                                      tooltip: 'Remove from bank deposits',
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Remove deposit'),
                                            content: const Text(
                                              'Are you sure you want to remove this loan from bank deposits?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Remove'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await controller.removeLoanFromBank(
                                            bankLoan.loanId,
                                          );
                                        }
                                      },
                                    ),
                                  ],
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
