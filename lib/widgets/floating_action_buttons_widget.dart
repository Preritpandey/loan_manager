import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';

class FloatingActionButtonsWidget extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback? onExportPDF;
  final VoidCallback? onAddLoan;

  const FloatingActionButtonsWidget({
    super.key,
    required this.isDesktop,
    this.onExportPDF,
    this.onAddLoan,
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return FloatingActionButton.extended(
        onPressed: onAddLoan ?? () => Get.toNamed('/add'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Add New Loan'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed:
                onExportPDF ?? () => Get.find<LoanController>().exportToPDF(),
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            elevation: 6,
            heroTag: 'export_pdf',
            child: const Icon(Icons.picture_as_pdf),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: onAddLoan ?? () => Get.toNamed('/add'),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            elevation: 6,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Loan'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      );
    }
  }
}
