import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';

class LoanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDesktop;
  final VoidCallback? onExportPDF;
  final VoidCallback? onRefresh;

  const LoanAppBar({
    super.key,
    required this.isDesktop,
    this.onExportPDF,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                fit: BoxFit.cover,
                "assets/icon.png",
                width: 30,
                height: 30,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loan Manager',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 204, 21, 27),
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: isDesktop ? 60 : 48,
      actions: [
        if (isDesktop) ...[
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: Colors.white,
              size: 20,
            ),
            onPressed:
                onExportPDF ?? () => Get.find<LoanController>().exportToPDF(),
            tooltip: 'Export to PDF',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed:
                onRefresh ?? () => Get.find<LoanController>().refreshLoans(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(isDesktop ? 60 : 48);
}
