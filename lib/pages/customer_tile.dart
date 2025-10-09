import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/customer_loans_page.dart';

class CustomerTile extends StatelessWidget {
  final String customerName;
  final List<Loan> customerLoans;

  const CustomerTile({
    super.key,
    required this.customerName,
    required this.customerLoans,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoanController>();
    final isOverdue = controller.isCustomerOverdue(customerName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCustomerDetails(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: isOverdue
                  ? [Colors.red[50]!, Colors.red[100]!]
                  : [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Customer Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverdue ? Colors.red[200] : Colors.blue[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person,
                  color: isOverdue ? Colors.red[700] : Colors.blue[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Customer Name and Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red[700] : Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${customerLoans.length} loan${customerLoans.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isOverdue ? Colors.red[600] : Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Indicators
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOverdue ? Colors.red : Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${customerLoans.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'loan${customerLoans.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isOverdue ? Colors.red[600] : Colors.blue[600],
                      fontWeight: FontWeight.w500,
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

  void _showCustomerDetails() {
    // Navigate to customer loans page showing all loans for this customer
    Get.to(
      () => CustomerLoansPage(
        customerName: customerName,
        customerLoans: customerLoans,
      ),
    );
  }
}
