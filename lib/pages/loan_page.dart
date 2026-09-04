import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/controllers/backup_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/widgets/loan_app_bar.dart';
import 'package:list/widgets/search_bar_widget.dart';
import 'package:list/widgets/search_suggestions_widget.dart';
import 'package:list/widgets/search_results_indicator_widget.dart';
import 'package:list/widgets/loan_summary_card.dart';
import 'package:list/widgets/loans_list_widget.dart';
import 'package:list/widgets/loading_state_widget.dart';
import 'package:list/widgets/empty_state_widget.dart';
import 'package:list/widgets/no_results_widget.dart';
import 'package:list/widgets/floating_action_buttons_widget.dart';
import 'package:list/widgets/customer_loan_tabs.dart';
import 'package:list/controllers/bank_loan_controller.dart';
import 'package:list/utils/nepali_date_utils.dart';

class LoanHomePage extends StatefulWidget {
  const LoanHomePage({super.key});

  @override
  State<LoanHomePage> createState() => _LoanHomePageState();
}

class _LoanHomePageState extends State<LoanHomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final LoanController controller = Get.put(LoanController());
  final RxBool _showOverdueOnly = false.obs;
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showSuggestions = false;
  bool _didAskBackupIdentity = false;
  CustomerLoanTab _selectedCustomerLoanTab = CustomerLoanTab.individual;

  @override
  void initState() {
    super.initState();
    print('=== LOAN PAGE INITIALIZED ===');
    print('Current local time: ${DateTime.now()}');
    print('Nepali date: ${NepaliDate.today().format()}');
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Initialize BankLoanController
    Get.put(BankLoanController());
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _askForBackupIdentity(),
    );
  }

  Future<void> _askForBackupIdentity() async {
    if (_didAskBackupIdentity) {
      return;
    }
    _didAskBackupIdentity = true;
    final backupController = Get.find<BackupController>();
    while (!backupController.isInitialized.value && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted || backupController.hasIdentity.value) {
      return;
    }
    await showBackupIdentityDialog(context, backupController);
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
        appBar: LoanAppBar(isDesktop: isDesktop),
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                // Bank Deposits Row - Centered at top
                // Container(
                //   width: double.infinity,
                //   padding: const EdgeInsets.symmetric(vertical: 8.0),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.grey.withOpacity(0.2),
                //         spreadRadius: 1,
                //         blurRadius: 3,
                //         offset: const Offset(0, 2),
                //       ),
                //     ],
                //   ),
                //   child: Center(
                //     child: Obx(() {
                //       final bankLoanController = Get.find<BankLoanController>();
                //       if (bankLoanController.isLoading.value ||
                //           bankLoanController.bankLoans.isEmpty) {
                //         return const SizedBox.shrink();
                //       }

                //       return Container(
                //         constraints: BoxConstraints(maxWidth: maxWidth),
                //         padding: const EdgeInsets.symmetric(horizontal: 16.0),
                //         child: Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           children: [
                //             // Bank Deposits Button
                //             ElevatedButton.icon(
                //               onPressed: () {
                //                 Get.to(() => BankLoansPage());
                //               },
                //               icon: const Icon(Icons.account_balance, size: 16),
                //               label: const Text('View Bank Deposits'),
                //               style: ElevatedButton.styleFrom(
                //                 backgroundColor: Colors.purple,
                //                 foregroundColor: Colors.white,
                //                 padding: const EdgeInsets.symmetric(
                //                   vertical: 8,
                //                   horizontal: 12,
                //                 ),
                //                 shape: RoundedRectangleBorder(
                //                   borderRadius: BorderRadius.circular(8),
                //                 ),
                //               ),
                //             ),

                //             const SizedBox(width: 16),

                //             // Total Amount in Bank
                //             Text(
                //               'Total in Bank: ',
                //               style: TextStyle(
                //                 fontSize: 14,
                //                 color: Colors.grey[700],
                //                 fontWeight: FontWeight.w500,
                //               ),
                //             ),
                //             Text(
                //               'रु ${bankLoanController.totalDepositedAmount.toStringAsFixed(2)}',
                //               style: const TextStyle(
                //                 fontSize: 14,
                //                 fontWeight: FontWeight.bold,
                //                 color: Color.fromARGB(255, 204, 21, 27),
                //               ),
                //             ),
                //           ],
                //         ),
                //       );
                //     }),
                //   ),
                // ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const LoadingStateWidget();
                      }

                      final groupedLoans = controller
                          .getLoansGroupedByCustomer();
                      final overdueGroupedLoans = controller
                          .getOverdueLoans()
                          .fold<Map<String, List<Loan>>>({}, (map, loan) {
                            map.putIfAbsent(loan.name, () => []).add(loan);
                            return map;
                          });
                      Map<String, List<Loan>> loansForTab(
                        bool hasFiveOrMoreLoans,
                      ) {
                        final entries = groupedLoans.entries.where(
                          (entry) =>
                              (entry.value.length >= 5) == hasFiveOrMoreLoans,
                        );
                        return Map<String, List<Loan>>.fromEntries(
                          entries
                              .map(
                                (entry) => MapEntry(
                                  entry.key,
                                  _showOverdueOnly.value
                                      ? overdueGroupedLoans[entry.key] ?? []
                                      : entry.value,
                                ),
                              )
                              .where((entry) => entry.value.isNotEmpty),
                        );
                      }

                      final individualLoans = loansForTab(false);
                      final customerLoans = loansForTab(true);
                      final selectedGroupedLoans =
                          _selectedCustomerLoanTab == CustomerLoanTab.individual
                          ? individualLoans
                          : customerLoans;
                      final customerNames = selectedGroupedLoans.keys.toList();

                      // Show empty state only if there are no loans at all
                      if (customerNames.isEmpty && controller.loans.isEmpty) {
                        return const EmptyStateWidget();
                      }

                      // Show no results state only after explicit search
                      if (controller.shouldShowNoResults()) {
                        return NoResultsWidget(
                          searchQuery: searchController.text,
                          onBackToAllLoans: () {
                            searchController.clear();
                            controller.clearSearch();
                            setState(() {
                              _showSuggestions = false;
                            });
                          },
                          onAddNewLoan: () => Get.toNamed('/add'),
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            // Search Bar
                            SearchBarWidget(
                              controller: searchController,
                              focusNode: searchFocusNode,
                              isDesktop: isDesktop,
                              padding: padding,
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
                              onClear: () {
                                searchController.clear();
                                controller.clearSearch();
                                setState(() {
                                  _showSuggestions = false;
                                });
                              },
                            ),

                            // Search Suggestions
                            if (_showSuggestions &&
                                controller.searchSuggestions.isNotEmpty)
                              SearchSuggestionsWidget(
                                suggestions: controller.searchSuggestions,
                                padding: padding,
                                isDesktop: isDesktop,
                                onSuggestionTap: (suggestion) {
                                  searchController.text = suggestion;
                                  controller.performExplicitSearch(suggestion);
                                  setState(() {
                                    _showSuggestions = false;
                                  });
                                  searchFocusNode.unfocus();
                                },
                              ),

                            // Search Results Indicator
                            if (controller.getIsSearchActive())
                              SearchResultsIndicatorWidget(
                                resultCount: controller
                                    .getFilteredLoans()
                                    .length,
                                padding: padding,
                                isDesktop: isDesktop,
                                onClear: () {
                                  searchController.clear();
                                  controller.clearSearch();
                                  setState(() {
                                    _showSuggestions = false;
                                  });
                                },
                              ),

                            // Single Summary Card
                            LoanSummaryCard(
                              padding: padding,
                              isDesktop: isDesktop,
                              totalLoans: controller.getTotalLoansCount(),
                              totalDue: controller.getTotalDueAmount(),
                              overdueLoans: controller.getOverdueLoansCount(),
                              totalReceived: controller
                                  .getTotalReceivedAmount(),
                              totalPrincipalDue: controller
                                  .getTotalPrincipalDue(),
                              totalInterestDue: controller
                                  .getTotalInterestDue(),
                              onOverdueTap: () {
                                _showOverdueOnly.value =
                                    !_showOverdueOnly.value;
                                if (_showOverdueOnly.value) {
                                  // Show only overdue loans
                                  final overdueLoans = controller
                                      .getOverdueLoans();
                                  controller.filteredLoans.value = overdueLoans;
                                } else {
                                  // Show all loans
                                  controller.filteredLoans.value =
                                      controller.loans;
                                }
                              },
                            ),

                            CustomerLoanTabs(
                              selectedTab: _selectedCustomerLoanTab,
                              individualCount: individualLoans.length,
                              customerCount: customerLoans.length,
                              onTabChanged: (tab) {
                                setState(() {
                                  _selectedCustomerLoanTab = tab;
                                });
                              },
                            ),

                            // Cash Deposits section
                            Padding(
                              padding: padding,
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.account_balance_wallet,
                                  ),
                                  title: const Text(
                                    'Cash Deposits',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Record and manage cash deposits with manual Nepali dates',
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () =>
                                        Get.toNamed('/cash-deposits'),
                                    child: const Text('Open'),
                                  ),
                                ),
                              ),
                            ),

                            // Show message when only overdue loans are being shown
                            if (_showOverdueOnly.value)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Showing overdue loans only. ',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _showOverdueOnly.value = false;
                                        controller.filteredLoans.value =
                                            controller.loans;
                                      },
                                      child: Text('Show all loans'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size(0, 0),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Loans List
                            LoansListWidget(
                              customerNames: customerNames,
                              groupedLoans: selectedGroupedLoans,
                              padding: padding,
                              isDesktop: isDesktop,
                              totalLoansCount: selectedGroupedLoans.values.fold(
                                0,
                                (total, loans) => total + loans.length,
                              ),
                            ),

                            // Bottom padding for FAB
                            const SizedBox(height: 100),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(height: 8),
            // Original FAB
            FloatingActionButtonsWidget(isDesktop: isDesktop),
          ],
        ),
      ),
    );
  }
}
