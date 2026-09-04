import 'package:flutter/material.dart';

enum CustomerLoanTab { individual, customer }

class CustomerLoanTabs extends StatelessWidget {
  const CustomerLoanTabs({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.individualCount,
    required this.customerCount,
  });

  final CustomerLoanTab selectedTab;
  final ValueChanged<CustomerLoanTab> onTabChanged;
  final int individualCount;
  final int customerCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<CustomerLoanTab>(
        segments: [
          ButtonSegment<CustomerLoanTab>(
            value: CustomerLoanTab.individual,
            icon: const Icon(Icons.person),
            label: Text('Individual Loans ($individualCount)'),
          ),
          ButtonSegment<CustomerLoanTab>(
            value: CustomerLoanTab.customer,
            icon: const Icon(Icons.people),
            label: Text('Customer Loans ($customerCount)'),
          ),
        ],
        selected: {selectedTab},
        onSelectionChanged: (selection) => onTabChanged(selection.first),
      ),
    );
  }
}
