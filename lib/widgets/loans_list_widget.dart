import 'package:flutter/material.dart';
import 'package:list/pages/customer_tile.dart';

class LoansListWidget extends StatelessWidget {
  final List<String> customerNames;
  final Map<String, dynamic> groupedLoans;
  final EdgeInsets padding;
  final bool isDesktop;
  final int totalLoansCount;

  const LoansListWidget({
    super.key,
    required this.customerNames,
    required this.groupedLoans,
    required this.padding,
    required this.isDesktop,
    required this.totalLoansCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: padding.copyWith(top: 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(bottom: BorderSide(color: Colors.blue[200]!)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Customer Loans (${customerNames.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const Spacer(),
                    if (isDesktop)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Total: $totalLoansCount loans',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: customerNames.length,
                itemBuilder: (context, index) {
                  final customerName = customerNames[index];
                  final customerLoans = groupedLoans[customerName]!;
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 200 + (index * 50)),
                    curve: Curves.easeOutBack,
                    child: CustomerTile(
                      customerName: customerName,
                      customerLoans: customerLoans,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
