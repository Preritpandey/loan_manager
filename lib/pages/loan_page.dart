import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
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
        appBar: LoanAppBar(isDesktop: isDesktop),
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const LoadingStateWidget();
                }

                final groupedLoans = controller.getLoansGroupedByCustomer();
                final customerNames = groupedLoans.keys.toList();

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
                          resultCount: controller.getFilteredLoans().length,
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
                        totalReceived: controller.getTotalReceivedAmount(),
                      ),

                      // Loans List
                      LoansListWidget(
                        customerNames: customerNames,
                        groupedLoans: groupedLoans,
                        padding: padding,
                        isDesktop: isDesktop,
                        totalLoansCount: controller.getTotalLoansCount(),
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
