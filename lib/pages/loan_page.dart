import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/pages/customer_tile.dart';

class LoanHomePage extends StatefulWidget {
  const LoanHomePage({super.key});

  @override
  State<LoanHomePage> createState() => _LoanHomePageState();
}

class _LoanHomePageState extends State<LoanHomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final LoanController controller = Get.put(LoanController());
  final searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.refreshLoans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;
    final isTablet = screenWidth > 600 && screenWidth <= 768;
    final maxWidth = isDesktop ? 1200.0 : double.infinity;
    final padding = EdgeInsets.symmetric(
      horizontal: isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0),
      vertical: isDesktop ? 24.0 : 16.0,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(isDesktop),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingState();
              }

              final groupedLoans = controller.getLoansGroupedByCustomer();
              final customerNames = groupedLoans.keys.toList();

              if (customerNames.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: [
                  // Search Bar
                  _buildSearchBar(padding, isDesktop),

                  // Summary Cards
                  _buildSummarySection(padding, isDesktop),

                  // Loans List
                  Expanded(
                    child: _buildLoansList(
                      customerNames,
                      groupedLoans,
                      padding,
                      isDesktop,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(isDesktop),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loan Manager',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Manage your loans efficiently',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: isDesktop ? 80 : 64,
      actions: [
        if (isDesktop) ...[
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.refreshLoans(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildSearchBar(EdgeInsets padding, bool isDesktop) {
    return Container(
      margin: padding.copyWith(bottom: 0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            controller: searchController,
            onChanged: (value) => controller.search(value),
            decoration: InputDecoration(
              hintText: isDesktop
                  ? 'Search by customer name, serial number, phone number, or address...'
                  : 'Search customers, serial, phone...',
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
                child: Icon(Icons.search, color: Colors.blue[700], size: 20),
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        controller.search('');
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
    );
  }

  Widget _buildSummarySection(EdgeInsets padding, bool isDesktop) {
    return Container(
      margin: padding,
      child: isDesktop ? _buildDesktopSummary() : _buildMobileSummary(),
    );
  }

  Widget _buildDesktopSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Loans',
            '${controller.getTotalLoansCount()}',
            Icons.receipt_long,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Total Due',
            'NPR ${controller.getTotalDueAmount().toStringAsFixed(2)}',
            Icons.account_balance,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Overdue',
            '${controller.getOverdueLoansCount()}',
            Icons.warning,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Received',
            'NPR ${controller.getTotalReceivedAmount().toStringAsFixed(2)}',
            Icons.payment,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSummary() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Loans',
                '${controller.getTotalLoansCount()}',
                Icons.receipt_long,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Overdue',
                '${controller.getOverdueLoansCount()}',
                Icons.warning,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Due',
                'NPR ${controller.getTotalDueAmount().toStringAsFixed(2)}',
                Icons.account_balance,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Received',
                'NPR ${controller.getTotalReceivedAmount().toStringAsFixed(2)}',
                Icons.payment,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (title == 'Overdue' && controller.getOverdueLoansCount() > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoansList(
    List<String> customerNames,
    Map<String, dynamic> groupedLoans,
    EdgeInsets padding,
    bool isDesktop,
  ) {
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
                          'Total: ${controller.getTotalLoansCount()} loans',
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
              Expanded(
                child: ListView.builder(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading loans...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: Colors.blue[300],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No loans found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start by adding your first loan using the + button below',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Tip: Use the search bar to find specific loans',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isDesktop) {
    return FloatingActionButton.extended(
      onPressed: () => Get.toNamed('/add'),
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.add_circle_outline),
      label: Text(isDesktop ? 'Add New Loan' : 'Add Loan'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

// // features/loan/pages/loan_home_page.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:list/controllers/loan_controller.dart';
// import 'package:list/pages/customer_tile.dart';

// class LoanHomePage extends StatefulWidget {
//   const LoanHomePage({super.key});

//   @override
//   State<LoanHomePage> createState() => _LoanHomePageState();
// }

// class _LoanHomePageState extends State<LoanHomePage>
//     with WidgetsBindingObserver {
//   final LoanController controller = Get.put(LoanController());
//   final searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     searchController.dispose();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       controller.refreshLoans();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Loan Manager'),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(50),
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: searchController,
//               onChanged: (value) => controller.search(value),
//               decoration: const InputDecoration(
//                 hintText: 'Search by customer name, serial, phone...',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.search),
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Obx(() {
//         if (controller.isLoading.value) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final groupedLoans = controller.getLoansGroupedByCustomer();
//         final customerNames = groupedLoans.keys.toList();

//         if (customerNames.isEmpty) {
//           return const Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.account_balance_wallet_outlined,
//                   size: 64,
//                   color: Colors.grey,
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   'No loans found',
//                   style: TextStyle(fontSize: 18, color: Colors.grey),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Add your first loan using the + button',
//                   style: TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//               ],
//             ),
//           );
//         }

//         return Column(
//           children: [
//             // Summary Card
//             Container(
//               margin: const EdgeInsets.all(8),
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.blue.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.blue.withOpacity(0.3)),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Total Loans: ${controller.getTotalLoansCount()}',
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Total Due: NPR ${controller.getTotalDueAmount().toStringAsFixed(2)}',
//                           style: const TextStyle(
//                             color: Colors.red,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         'Overdue: ${controller.getOverdueLoansCount()}',
//                         style: const TextStyle(
//                           color: Colors.red,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Received: NPR ${controller.getTotalReceivedAmount().toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           color: Colors.green,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             // Loans List
//             Expanded(
//               child: ListView.builder(
//                 itemCount: customerNames.length,
//                 itemBuilder: (context, index) {
//                   final customerName = customerNames[index];
//                   final customerLoans = groupedLoans[customerName]!;
//                   return CustomerTile(
//                     customerName: customerName,
//                     customerLoans: customerLoans,
//                   );
//                 },
//               ),
//             ),
//           ],
//         );
//       }),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => Get.toNamed('/add'),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
