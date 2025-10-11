import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/customer_loans_list_widget.dart';
import 'package:list/widgets/search_results_indicator_widget.dart';

class CustomerLoansPage extends StatefulWidget {
  final String customerName;
  final List<Loan> customerLoans;

  const CustomerLoansPage({
    super.key,
    required this.customerName,
    required this.customerLoans,
  });

  @override
  State<CustomerLoansPage> createState() => _CustomerLoansPageState();
}

class _CustomerLoansPageState extends State<CustomerLoansPage> {
  late LoanController controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    controller = Get.find<LoanController>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Loan> _getFilteredLoans() {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return widget.customerLoans;
    return widget.customerLoans.where((loan) {
      final serial = loan.serialNumber.toLowerCase();
      final jewellery = loan.jewelleryName.toLowerCase();
      return serial.contains(q) || jewellery.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;
    final maxWidth = isDesktop ? 1000.0 : double.infinity;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customerName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${widget.customerLoans.length} loan${widget.customerLoans.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 204, 21, 27),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Add New Loan Button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addNewLoanForCustomer(),
            tooltip: 'Add new loan for this customer',
          ),
          // PDF Download Button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _downloadCustomerPDF(),
            tooltip: 'Download PDF for all loans',
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: maxWidth,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Summary Card
                _buildCustomerSummaryCard(),
                const SizedBox(height: 16),

                // Search Bar for this customer's loans
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onSubmitted: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: isDesktop
                            ? 'Search by serial number or jewellery name'
                            : 'Serial number or jewellery name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.search,
                              color: Colors.blue[700], size: 20),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                if (_searchQuery.isNotEmpty)
                  SearchResultsIndicatorWidget(
                    resultCount: _getFilteredLoans().length,
                    padding:
                        EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                    isDesktop: isDesktop,
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),

                // Individual Loans List
                CustomerLoansListWidget(
                  customerName: widget.customerName,
                  customerLoans: _getFilteredLoans(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSummaryCard() {
    final totalDueAmount = controller.getTotalDueAmountForCustomer(
      widget.customerName,
    );
    final totalAmountGiven = widget.customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.amountGiven,
    );
    final totalAmountReceived = widget.customerLoans.fold(
      0.0,
      (sum, loan) => sum + loan.amountReceived,
    );
    final totalFixedInterest = controller.getTotalFixedInterestForCustomer(
      widget.customerName,
    );
    final totalOverdueInterest = controller.getTotalOverdueInterestForCustomer(
      widget.customerName,
    );
    final isOverdue = controller.isCustomerOverdue(widget.customerName);
    final totalOverdueDays = controller.getTotalOverdueDaysForCustomer(
      widget.customerName,
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isOverdue
                ? [Colors.red[50]!, Colors.red[100]!]
                : [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: isOverdue ? Colors.red[700] : Colors.blue[700],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.customerName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isOverdue ? Colors.red[700] : Colors.blue[700],
                      ),
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Financial Summary
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Given',
                      'NPR ${totalAmountGiven.toStringAsFixed(2)}',
                      Colors.blue,
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Received',
                      'NPR ${totalAmountReceived.toStringAsFixed(2)}',
                      Colors.green,
                      Icons.payments,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Fixed Interest',
                      'NPR ${totalFixedInterest.toStringAsFixed(2)}',
                      Colors.orange,
                      Icons.percent,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Due',
                      'NPR ${totalDueAmount.toStringAsFixed(2)}',
                      totalDueAmount > 0 ? Colors.red : Colors.green,
                      Icons.account_balance,
                    ),
                  ),
                ],
              ),
              if (isOverdue) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Overdue Days',
                        '$totalOverdueDays days',
                        Colors.red,
                        Icons.schedule,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Overdue Interest',
                        'NPR ${totalOverdueInterest.toStringAsFixed(2)}',
                        Colors.red,
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
              ],

              // Customer Info
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Phone: ${widget.customerLoans.first.phone}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Address: ${widget.customerLoans.first.address}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _addNewLoanForCustomer() {
    // Navigate to add loan page with pre-filled customer information
    final existingLoan = widget.customerLoans.first;

    final arguments = {
      'customerName': widget.customerName,
      'phone': existingLoan.phone,
      'address': existingLoan.address,
      'serialNumber': '', // Leave serial number empty for new collateral
    };

    print('🔧 CustomerLoansPage: Adding new loan for existing customer');
    print('🔧 Customer Name: ${widget.customerName}');
    print('🔧 Phone: ${existingLoan.phone}');
    print('🔧 Address: ${existingLoan.address}');
    print('🔧 Arguments being passed: $arguments');

    Get.toNamed('/add', arguments: arguments);
  }

  Future<void> _downloadCustomerPDF() async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Generate PDF for this customer only
      await controller.exportCustomerLoansToPDF(widget.customerName);

      // Close loading dialog
      Get.back();

      Get.snackbar(
        'Success',
        'PDF downloaded successfully for ${widget.customerName}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Failed to download PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
