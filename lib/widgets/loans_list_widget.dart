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
        elevation: 3,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 204, 21, 27).withOpacity(0.06),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color.fromARGB(255, 204, 21, 27).withOpacity(0.25),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Color.fromARGB(255, 204, 21, 27)),
                    const SizedBox(width: 8),
                    const Text(
                      'Customer Loans',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 204, 21, 27),
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
                          color: const Color.fromARGB(255, 204, 21, 27).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Total Loans',
                          style: TextStyle(
                            color: Color.fromARGB(255, 204, 21, 27),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: customerNames.length,
                itemBuilder: (context, index) {
                  final customerName = customerNames[index];
                  final customerLoans = groupedLoans[customerName]!;
                  return AnimatedContainer(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    duration: Duration(milliseconds: 200 + (index * 50)),
                    curve: Curves.easeOutCubic,
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
