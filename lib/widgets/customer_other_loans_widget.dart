import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/loan_detail_page.dart';
import 'package:list/pages/customer_loans_page.dart';

class CustomerOtherLoansWidget extends StatelessWidget {
  final Loan currentLoan;

  const CustomerOtherLoansWidget({super.key, required this.currentLoan});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoanController>();
    final allCustomerLoans = controller.getLoansByCustomerName(
      currentLoan.name,
    );
    final otherLoans = allCustomerLoans
        .where((loan) => loan.serialNumber != currentLoan.serialNumber)
        .toList();

    // Don't show widget if customer has only one loan
    if (otherLoans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Other Loans for ${currentLoan.name}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${otherLoans.length} more',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Other Loans List
              ...otherLoans.map((loan) => _buildOtherLoanTile(loan)).toList(),

              // Action Buttons
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addNewLoanForCustomer(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add New Loan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewAllCustomerLoans(),
                      icon: const Icon(Icons.list_alt, size: 18),
                      label: const Text('View All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildOtherLoanTile(Loan loan) {
    final isOverdue = loan.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: () => _navigateToLoan(loan),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isOverdue ? Colors.red[50] : Colors.white,
              border: Border.all(
                color: isOverdue ? Colors.red[200]! : Colors.grey[200]!,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Loan Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.diamond,
                              size: 16,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${loan.type} - ${loan.jewelleryName}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Serial: ${loan.serialNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'NPR ${loan.amountGiven.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${loan.interestRate}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Due Amount and Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'NPR ${loan.dueAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? Colors.red[600] : Colors.blue[600],
                        ),
                      ),
                      if (isOverdue)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'OVERDUE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLoan(Loan loan) {
    Get.to(() => LoanDetailPage(loan: loan))?.then((_) {
      // Refresh the loans list when returning from detail page
      final controller = Get.find<LoanController>();
      controller.refreshLoans();
      controller.refreshLoanCalculations();
    });
  }

  void _addNewLoanForCustomer() {
    // Navigate to add loan page with pre-filled customer information
    Get.toNamed(
      '/add',
      arguments: {
        'customerName': currentLoan.name,
        'phone': currentLoan.phone,
        'address': currentLoan.address,
        'serialNumber': currentLoan.serialNumber, // Use same serial number
      },
    );
  }

  void _viewAllCustomerLoans() {
    final controller = Get.find<LoanController>();
    final allCustomerLoans = controller.getLoansByCustomerName(
      currentLoan.name,
    );

    Get.to(
      () => CustomerLoansPage(
        customerName: currentLoan.name,
        customerLoans: allCustomerLoans,
      ),
    );
  }
}
