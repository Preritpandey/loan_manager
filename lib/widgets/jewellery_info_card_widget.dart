import 'package:flutter/material.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/info_card_widget.dart';
import 'package:list/widgets/info_row_widget.dart';

class JewelleryInfoCard extends StatelessWidget {
  final Loan loan;

  const JewelleryInfoCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Collateral Information',
      titleIcon: Icons.diamond,
      titleColor: Colors.orange[700],
      children: [
        InfoRow(label: 'Type', value: loan.type, icon: Icons.category),
        InfoRow(
          label: 'Jewellery Name',
          value: loan.jewelleryName,
          icon: Icons.diamond_outlined,
        ),
        InfoRow(
          label: 'Serial Number',
          value: loan.serialNumber,
          icon: Icons.qr_code,
        ),
      ],
    );
  }
}
