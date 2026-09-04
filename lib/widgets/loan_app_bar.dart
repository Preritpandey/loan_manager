import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/bank_loan_controller.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/pages/bank_loans_page.dart';

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
      title: Obx(() {
        final bankLoanController = Get.find<BankLoanController>();
        final showBankInfo =
            !bankLoanController.isLoading.value &&
            bankLoanController.bankLoans.isNotEmpty;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Icon and Title
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 24,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Loan Manager',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 200),
            // Separator with increased spacing
            if (showBankInfo) ...[
              const SizedBox(width: 24), // Increased spacing before bank info
              const VerticalDivider(
                color: Colors.white54,
                thickness: 1,
                indent: 8,
                endIndent: 8,
                width: 24,
              ),
              const SizedBox(width: 16), // Additional spacing after divider
            ] else
              const SizedBox(width: 8),

            // Bank Deposits Info
            if (showBankInfo) ...[
              // Bank Deposits Button - Larger
              ElevatedButton.icon(
                onPressed: () => Get.to(() => BankLoansPage()),
                icon: const Icon(
                  Icons.account_balance,
                  size: 16,
                ), // Slightly larger icon
                label: const Text(
                  'View Bank Deposits',
                  style: TextStyle(fontSize: 14), // Larger font
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6, // Increased vertical padding
                    horizontal: 12, // Increased horizontal padding
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      6,
                    ), // Slightly larger border radius
                  ),
                  minimumSize: const Size(
                    0,
                    36,
                  ), // Minimum height for better touch target
                ),
              ),

              const SizedBox(width: 8),

              // Total Amount in Bank - Larger and more prominent
              const SizedBox(width: 8), // Added spacing before amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      'Bank: ',
                      style: TextStyle(
                        fontSize: 13, // Slightly larger
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'रु ${bankLoanController.totalDepositedAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14, // Larger font for amount
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      }),
      backgroundColor: Color.fromARGB(255, 210, 28, 34),
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: isDesktop ? 80 : 68,
      actions: [
        if (isDesktop) ...[
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () async {
              final ctrl = Get.find<LoanController>();
              await showMenu<String>(
                context: context,
                position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
                items: const [
                  PopupMenuItem<String>(value: 'today', child: Text('Today')),
                  PopupMenuItem<String>(
                    value: 'whole',
                    child: Text('Whole loans report'),
                  ),
                ],
              ).then((selection) async {
                if (selection == 'today') {
                  await ctrl.exportTodayReportToPDF();
                } else if (selection == 'whole') {
                  if (onExportPDF != null) {
                    onExportPDF!();
                  } else {
                    await ctrl.exportToPDF();
                  }
                }
              });
            },
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
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
            onPressed: () => Get.toNamed('/backup'),
            tooltip: 'Backup & Restore',
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(isDesktop ? 60 : 48);
}
