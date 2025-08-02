import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';
import 'package:list/widgets/info_row_widget.dart';

class PersonalInfoCard extends StatelessWidget {
  final Loan loan;

  const PersonalInfoCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Personal Information',
      titleIcon: Icons.person,
      titleColor: Colors.blue[700],
      children: [
        InfoRow(label: 'Name', value: loan.name, icon: Icons.person_outline),
        InfoRow(label: 'Phone', value: loan.phone, icon: Icons.phone_outlined),
        InfoRow(
          label: 'Address',
          value: loan.address,
          icon: Icons.location_on_outlined,
        ),
      ],
    );
  }
}
