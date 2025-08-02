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
  final searchFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showSuggestions = false;

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
    searchFocusNode.dispose();
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

    return GestureDetector(
      onTap: () {
        // Hide suggestions when tapping outside
        if (_showSuggestions) {
          setState(() {
            _showSuggestions = false;
          });
        }
        searchFocusNode.unfocus();
      },
      child: Scaffold(
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

                // Show empty state only if there are no loans at all
                if (customerNames.isEmpty && controller.loans.isEmpty) {
                  return _buildEmptyState();
                }

                // Show no results state only after explicit search
                if (controller.shouldShowNoResults()) {
                  return _buildNoResultsState();
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Search Bar
                      _buildSearchBar(padding, isDesktop),

                      // Search Suggestions
                      if (_showSuggestions &&
                          controller.searchSuggestions.isNotEmpty)
                        _buildSearchSuggestions(padding, isDesktop),

                      // Search Results Indicator
                      if (controller.getIsSearchActive())
                        _buildSearchResultsIndicator(padding, isDesktop),

                      // Single Summary Card
                      _buildSingleSummaryCard(padding, isDesktop),

                      // Loans List
                      _buildLoansList(
                        customerNames,
                        groupedLoans,
                        padding,
                        isDesktop,
                      ),

                      // Bottom padding for FAB
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(isDesktop),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
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
            onPressed: () => controller.exportToPDF(),
            tooltip: 'Export to PDF',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: () => controller.refreshLoans(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
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
            focusNode: searchFocusNode,
            onChanged: (value) {
              controller.search(value);
              setState(() {
                _showSuggestions = value.isNotEmpty;
              });
            },
            onSubmitted: (value) {
              controller.performExplicitSearch(value);
              setState(() {
                _showSuggestions = false;
              });
            },
            onTap: () {
              if (searchController.text.isNotEmpty) {
                setState(() {
                  _showSuggestions = true;
                });
              }
            },
            decoration: InputDecoration(
              hintText: isDesktop
                  ? 'Search by customer name, serial number ...'
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
                        controller.clearSearch();
                        setState(() {
                          _showSuggestions = false;
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
    );
  }

  Widget _buildSearchSuggestions(EdgeInsets padding, bool isDesktop) {
    return Container(
      margin: padding.copyWith(top: 4, bottom: 0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controller.searchSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = controller.searchSuggestions[index];
              return ListTile(
                leading: Icon(Icons.search, color: Colors.blue[700], size: 20),
                title: Text(suggestion, style: const TextStyle(fontSize: 14)),
                onTap: () {
                  searchController.text = suggestion;
                  controller.performExplicitSearch(suggestion);
                  setState(() {
                    _showSuggestions = false;
                  });
                  searchFocusNode.unfocus();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsIndicator(EdgeInsets padding, bool isDesktop) {
    return Container(
      margin: padding.copyWith(top: 8, bottom: 0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Search Results: ${controller.getFilteredLoans().length} loans found',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: isDesktop ? 14 : 12,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  searchController.clear();
                  controller.clearSearch();
                  setState(() {
                    _showSuggestions = false;
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleSummaryCard(EdgeInsets padding, bool isDesktop) {
    return Container(
      margin: padding,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loan Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Loans',
                      '${controller.getTotalLoansCount()}',
                      Icons.receipt_long,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Due',
                      'NPR ${controller.getTotalDueAmount().toStringAsFixed(0)}',
                      Icons.account_balance,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Overdue',
                      '${controller.getOverdueLoansCount()}',
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryItem(
                      'Received',
                      'NPR ${controller.getTotalReceivedAmount().toStringAsFixed(0)}',
                      Icons.payment,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
                    'Tip: Use the search bar to find\nspecific loans',
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

  Widget _buildNoResultsState() {
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
              child: Icon(Icons.search_off, size: 80, color: Colors.blue[300]),
            ),
            const SizedBox(height: 32),
            Text(
              'No results found for "${searchController.text}"',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Try a different search term or add a new loan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    searchController.clear();
                    controller.clearSearch();
                    setState(() {
                      _showSuggestions = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to All Loans'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Loan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                    'Tip: Try searching by name, serial number,\nor phone number',
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
    if (isDesktop) {
      return FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/add'),
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
            onPressed: () => controller.exportToPDF(),
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            elevation: 6,
            heroTag: 'export_pdf',
            child: const Icon(Icons.picture_as_pdf),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () => Get.toNamed('/add'),
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
