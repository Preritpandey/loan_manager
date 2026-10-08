import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/deposit_controller.dart';
import 'package:list/models/deposit.dart';
import 'package:list/utils/nepali_date_utils.dart';
import 'package:list/widgets/search_bar_widget.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as picker;

const _brandRed = Color.fromARGB(255, 204, 21, 27);
const _surface = Colors.white;
const _pageBg = Color(0xFFF6F7FA);
const _textStrong = Color(0xFF1F2933);
const _textMuted = Color(0xFF667085);
const _softRed = Color(0xFFFFF1F2);
const _softGreen = Color(0xFFEFFAF2);
const _softBlue = Color(0xFFEFF6FF);
const _softAmber = Color(0xFFFFF7E8);

enum _StatementFilter { all, deposits, withdrawals }
enum _DepositStatusSection { active, paidOut }

class CashDepositsPage extends StatefulWidget {
  const CashDepositsPage({super.key});

  @override
  State<CashDepositsPage> createState() => _CashDepositsPageState();
}

class _CashDepositsPageState extends State<CashDepositsPage> {
  final DepositController controller = Get.put(DepositController());
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  _DepositStatusSection _selectedStatusSection = _DepositStatusSection.active;

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 768;
    final maxWidth = isDesktop ? 1180.0 : double.infinity;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text(
          'Cash Deposit Ledger',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brandRed,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download All',
            onPressed: () => controller.exportAllDepositsToPDF(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Customer Deposit',
            onPressed: () => Get.to(() => const AddDepositPage()),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: maxWidth,
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final allDeposits = controller.filtered;
            final activeDeposits = allDeposits
                .where((deposit) => !_isPaidOutDeposit(deposit))
                .toList();
            final paidOutDeposits = allDeposits
                .where(_isPaidOutDeposit)
                .toList();
            final deposits = _selectedStatusSection ==
                    _DepositStatusSection.active
                ? activeDeposits
                : paidOutDeposits;
            final totalPrincipal = deposits.fold<double>(
              0,
              (sum, item) => sum + item.totalPrincipal,
            );
            final totalInterest = deposits.fold<double>(
              0,
              (sum, item) => sum + item.acquiredInterest,
            );

            return ListView(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              children: [
                _PortfolioSummary(
                  customers: deposits.length,
                  principal: totalPrincipal,
                  interest: totalInterest,
                ),
                const SizedBox(height: 12),
                SearchBarWidget(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  isDesktop: isDesktop,
                  padding: EdgeInsets.zero,
                  onChanged: controller.search,
                  onSubmitted: controller.search,
                  onTap: () {},
                  onClear: () {
                    searchController.clear();
                    controller.clearSearch();
                  },
                ),
                const SizedBox(height: 12),
                _DepositStatusTabs(
                  selectedSection: _selectedStatusSection,
                  activeCount: activeDeposits.length,
                  paidOutCount: paidOutDeposits.length,
                  onChanged: (section) {
                    setState(() => _selectedStatusSection = section);
                  },
                ),
                const SizedBox(height: 12),
                if (deposits.isEmpty)
                  _EmptyLedger(
                    message: _selectedStatusSection ==
                            _DepositStatusSection.active
                        ? 'No active cash deposits found'
                        : 'No paid out cash deposits found',
                  )
                else
                  ...deposits.map(
                    (deposit) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DepositTile(deposit: deposit),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  bool _isPaidOutDeposit(DepositModel deposit) {
    return deposit.totalAmountOwed <= 0.005;
  }
}

class _PortfolioSummary extends StatelessWidget {
  final int customers;
  final double principal;
  final double interest;

  const _PortfolioSummary({
    required this.customers,
    required this.principal,
    required this.interest,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: Icons.account_balance_wallet_outlined,
                color: _brandRed,
                background: _softRed,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Deposit Summary',
                  style: TextStyle(
                    color: _textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: _primaryButtonStyle(),
                onPressed: () => Get.to(() => const AddDepositPage()),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Account'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                label: 'Customers',
                value: '$customers',
                icon: Icons.people_outline,
                color: Colors.blue,
                background: _softBlue,
              ),
              _Metric(
                label: 'Principal',
                value: _money(principal),
                icon: Icons.savings_outlined,
                color: Colors.green,
                background: _softGreen,
              ),
              _Metric(
                label: 'Interest',
                value: _money(interest),
                icon: Icons.trending_up,
                color: Colors.orange,
                background: _softAmber,
              ),
              _Metric(
                label: 'Total Owed',
                value: _money(principal + interest),
                icon: Icons.payments_outlined,
                color: _brandRed,
                background: _softRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepositStatusTabs extends StatelessWidget {
  final _DepositStatusSection selectedSection;
  final int activeCount;
  final int paidOutCount;
  final ValueChanged<_DepositStatusSection> onChanged;

  const _DepositStatusTabs({
    required this.selectedSection,
    required this.activeCount,
    required this.paidOutCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(10),
      child: SegmentedButton<_DepositStatusSection>(
        segments: [
          ButtonSegment<_DepositStatusSection>(
            value: _DepositStatusSection.active,
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: Text('Active ($activeCount)'),
          ),
          ButtonSegment<_DepositStatusSection>(
            value: _DepositStatusSection.paidOut,
            icon: const Icon(Icons.check_circle_outline),
            label: Text('Paid Out ($paidOutCount)'),
          ),
        ],
        selected: {selectedSection},
        onSelectionChanged: (selection) => onChanged(selection.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _brandRed;
            return _textStrong;
          }),
        ),
      ),
    );
  }
}

class _DepositTile extends StatelessWidget {
  final DepositModel deposit;

  const _DepositTile({required this.deposit});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: InkWell(
        onTap: () => Get.to(() => DepositDetailPage(depositId: deposit.depositId)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _InitialBadge(name: deposit.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deposit.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textStrong,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${deposit.phone}  |  ${deposit.transactions.length} transaction(s)  |  Latest ${deposit.latestTransactionDateNepali}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _money(deposit.totalAmountOwed),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textStrong,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Principal ${_money(deposit.totalPrincipal)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'View ledger',
                onPressed: () =>
                    Get.to(() => DepositDetailPage(depositId: deposit.depositId)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddDepositPage extends StatefulWidget {
  const AddDepositPage({super.key});

  @override
  State<AddDepositPage> createState() => _AddDepositPageState();
}

class _AddDepositPageState extends State<AddDepositPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final addrCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final DepositController controller = Get.find<DepositController>();

  @override
  void dispose() {
    nameCtrl.dispose();
    addrCtrl.dispose();
    phoneCtrl.dispose();
    descCtrl.dispose();
    amountCtrl.dispose();
    rateCtrl.dispose();
    dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text(
          'New Cash Deposit',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _brandRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Panel(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(
                    icon: Icons.person_outline,
                    title: 'Customer',
                  ),
                  _field(nameCtrl, 'Customer Name'),
                  _field(phoneCtrl, 'Phone Number'),
                  _field(addrCtrl, 'Address'),
                  _field(descCtrl, 'Description', required: false),
                  const SizedBox(height: 16),
                  const _SectionTitle(
                    icon: Icons.savings_outlined,
                    title: 'Deposit Lot',
                  ),
                  _moneyField(amountCtrl, 'Initial Deposit Amount'),
                  _moneyField(rateCtrl, 'Interest Rate %'),
                  _dateField(context, dateCtrl, 'Deposit Date'),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.check),
                      label: const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(amountCtrl.text.trim());
    final rate = double.parse(rateCtrl.text.trim());
    final confirmed = await _confirm(
      context,
      'Create deposit account?',
      'Initial deposit ${_money(amount)} at $rate% on ${dateCtrl.text.trim()}.',
    );
    if (!confirmed) return;

    final model = DepositModel(
      name: nameCtrl.text.trim(),
      address: addrCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      interestRate: rate,
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
    );
    model.addDepositLot(
      amount: amount,
      nepaliDateString: dateCtrl.text.trim(),
      rate: rate,
      description: 'Initial deposit',
    );
    controller.addDepositAccount(model);
    Get.back();
  }
}

class DepositDetailPage extends StatefulWidget {
  final String depositId;

  const DepositDetailPage({super.key, required this.depositId});

  @override
  State<DepositDetailPage> createState() => _DepositDetailPageState();
}

class _DepositDetailPageState extends State<DepositDetailPage> {
  _StatementFilter _filter = _StatementFilter.all;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DepositController>();
    return Obx(() {
      final model = controller.getById(widget.depositId);
      if (model == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Deposit Ledger')),
          body: const Center(child: Text('Account not found')),
        );
      }
      return Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          title: Text(
            model.name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: _brandRed,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.autorenew),
              tooltip: 'Process Interest',
              onPressed: () => controller.processInterest(widget.depositId),
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Download PDF',
              onPressed: () =>
                  controller.exportCustomerDepositToPDF(widget.depositId),
            ),
          ],
        ),
        floatingActionButton: _LedgerActions(
          deposit: model,
          controller: controller,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CustomerSummary(deposit: model),
            const SizedBox(height: 12),
            _StatementHeader(
              filter: _filter,
              onChanged: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 8),
            if (_filteredTransactions(model).isEmpty)
              const _EmptyLedger()
            else
              ..._filteredTransactions(model).map(
                (txn) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TransactionTile(transaction: txn),
                ),
              ),
          ],
        ),
      );
    });
  }

  List<DepositTransaction> _filteredTransactions(DepositModel model) {
    final transactions = model.transactionsSortedDesc;
    return switch (_filter) {
      _StatementFilter.all => transactions,
      _StatementFilter.deposits =>
        transactions.where((txn) => txn.type == 'Deposit').toList(),
      _StatementFilter.withdrawals =>
        transactions.where((txn) => txn.type == 'Withdrawal').toList(),
    };
  }
}

class _CustomerSummary extends StatelessWidget {
  final DepositModel deposit;

  const _CustomerSummary({required this.deposit});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialBadge(name: deposit.name, large: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deposit.name,
                      style: const TextStyle(
                        color: _textStrong,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${deposit.phone}  |  ${deposit.address}',
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(text: '${deposit.interestRate}% Rate'),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Metric(
                label: 'Principal',
                value: _money(deposit.totalPrincipal),
                icon: Icons.savings_outlined,
                color: Colors.green,
                background: _softGreen,
              ),
              _Metric(
                label: 'Interest',
                value: _money(deposit.acquiredInterest),
                icon: Icons.trending_up,
                color: Colors.orange,
                background: _softAmber,
              ),
              _Metric(
                label: 'Total Owed',
                value: _money(deposit.totalAmountOwed),
                icon: Icons.payments_outlined,
                color: _brandRed,
                background: _softRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatementHeader extends StatelessWidget {
  final _StatementFilter filter;
  final ValueChanged<_StatementFilter> onChanged;

  const _StatementHeader({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.receipt_long,
            title: 'Statement',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipButton(
                label: 'Normal',
                selected: filter == _StatementFilter.all,
                onTap: () => onChanged(_StatementFilter.all),
              ),
              _FilterChipButton(
                label: 'Deposits Only',
                selected: filter == _StatementFilter.deposits,
                onTap: () => onChanged(_StatementFilter.deposits),
              ),
              _FilterChipButton(
                label: 'Withdrawals Only',
                selected: filter == _StatementFilter.withdrawals,
                onTap: () => onChanged(_StatementFilter.withdrawals),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: const Color(0xFFF3F5F7),
      selectedColor: _brandRed.withValues(alpha: 0.14),
      side: BorderSide(
        color: selected
            ? _brandRed.withValues(alpha: 0.30)
            : Colors.grey.withValues(alpha: 0.22),
      ),
      labelStyle: TextStyle(
        color: selected ? _brandRed : const Color(0xFF313946),
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final DepositTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == 'Deposit' ||
        transaction.type == 'Interest Applied';
    final title = transaction.source ?? transaction.type;
    final amountPrefix = isCredit ? '+' : '-';
    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(
            icon: isCredit ? Icons.south_west : Icons.north_east,
            color: isCredit ? Colors.green : _brandRed,
            background: isCredit ? _softGreen : _softRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.dateNepali,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _BalanceTag(
                      label: 'Principal',
                      value: _money(transaction.principalBalanceAfter),
                    ),
                    _BalanceTag(
                      label: 'Interest',
                      value: _money(transaction.interestBalanceAfter),
                    ),
                    _BalanceTag(
                      label: 'Total',
                      value: _money(transaction.totalBalanceAfter),
                    ),
                  ],
                ),
                if (transaction.description != null &&
                    transaction.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(transaction.description!),
                  ),
              ],
            ),
          ),
          Text(
            '$amountPrefix${_money(transaction.amount)}',
            style: TextStyle(
              color: isCredit ? Colors.green[800] : Colors.red[800],
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceTag extends StatelessWidget {
  final String label;
  final String value;

  const _BalanceTag({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InitialBadge extends StatelessWidget {
  final String name;
  final bool large;

  const _InitialBadge({required this.name, this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 46.0 : 40.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _softRed,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _brandRed.withValues(alpha: 0.18)),
      ),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
          color: _brandRed,
          fontSize: large ? 18 : 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;

  const _IconBadge({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

class _LedgerActions extends StatelessWidget {
  final DepositModel deposit;
  final DepositController controller;

  const _LedgerActions({required this.deposit, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'add_deposit_$deposit',
          backgroundColor: _brandRed,
          foregroundColor: Colors.white,
          onPressed: () => _showAddDepositDialog(context, controller, deposit),
          icon: const Icon(Icons.add),
          label: const Text('Deposit'),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'withdraw_$deposit',
          backgroundColor: const Color(0xFF26313F),
          foregroundColor: Colors.white,
          onPressed: () => _showWithdrawDialog(context, controller, deposit),
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Withdraw'),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  final Color? background;

  const _Metric({
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final metricColor = color ?? _brandRed;
    final metricBackground = background ?? _softRed;
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: metricBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: metricColor.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: metricColor),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: metricColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textStrong,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _brandRed),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;

  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final color = text.contains('Eligible')
        ? Colors.orange
        : text.contains('Fully')
            ? Colors.grey
            : text.contains('Partially')
                ? Colors.blue
                : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  final String message;

  const _EmptyLedger({this.message = 'No cash deposit records found'});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(message),
        ),
      ),
    );
  }
}

Future<void> _showAddDepositDialog(
  BuildContext context,
  DepositController controller,
  DepositModel deposit,
) async {
  final formKey = GlobalKey<FormState>();
  final amountCtrl = TextEditingController();
  final rateCtrl = TextEditingController(text: deposit.interestRate.toString());
  final dateCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add Deposit Lot'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _moneyField(amountCtrl, 'Amount'),
              _moneyField(rateCtrl, 'Interest Rate %'),
              _dateField(context, dateCtrl, 'Deposit Date'),
              _field(descCtrl, 'Description', required: false),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final amount = double.parse(amountCtrl.text.trim());
            final rate = double.parse(rateCtrl.text.trim());
            final confirmed = await _confirm(
              context,
              'Record deposit?',
              '${_money(amount)} at $rate% on ${dateCtrl.text.trim()}.',
            );
            if (!confirmed) return;
            controller.addDepositLot(
              depositId: deposit.depositId,
              amount: amount,
              nepaliDate: dateCtrl.text.trim(),
              interestRate: rate,
              description:
                  descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> _showWithdrawDialog(
  BuildContext context,
  DepositController controller,
  DepositModel deposit,
) async {
  final formKey = GlobalKey<FormState>();
  final amountCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  var source = 'principal';

  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
        final allocations = source == 'principal' && amount > 0
            ? controller.previewPrincipalWithdrawal(
                depositId: deposit.depositId,
                amount: amount,
              )
            : <DepositWithdrawalAllocation>[];
        return AlertDialog(
          title: const Text('Withdraw'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: source,
                    decoration: const InputDecoration(labelText: 'Source'),
                    items: const [
                      DropdownMenuItem(
                        value: 'principal',
                        child: Text('Principal'),
                      ),
                      DropdownMenuItem(
                        value: 'interest',
                        child: Text('Acquired Interest'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => source = value ?? 'principal',
                    ),
                  ),
                  _moneyField(
                    amountCtrl,
                    'Amount',
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= 0) return 'Required';
                      final available = source == 'principal'
                          ? deposit.totalPrincipal
                          : deposit.acquiredInterest;
                      if (parsed > available) {
                        return 'Available ${_money(available)}';
                      }
                      return null;
                    },
                  ),
                  _dateField(context, dateCtrl, 'Withdrawal Date'),
                  _field(descCtrl, 'Description', required: false),
                  if (allocations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Principal allocation',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    ...allocations.map(
                      (item) => Text(
                        '${item.lot.depositDate}: ${_money(item.amount)}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final amount = double.parse(amountCtrl.text.trim());
                final confirmed = await _confirm(
                  context,
                  'Record withdrawal?',
                  '${_money(amount)} from ${source == 'principal' ? 'principal' : 'acquired interest'} on ${dateCtrl.text.trim()}.',
                );
                if (!confirmed) return;
                controller.withdraw(
                  depositId: deposit.depositId,
                  amount: amount,
                  nepaliDate: dateCtrl.text.trim(),
                  source: source,
                  description:
                      descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Withdraw'),
            ),
          ],
        );
      },
    ),
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool required = true,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    ),
  );
}

Widget _moneyField(
  TextEditingController controller,
  String label, {
  ValueChanged<String>? onChanged,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(label),
      validator: validator ??
          (value) {
            final parsed = double.tryParse(value?.trim() ?? '');
            if (parsed == null || parsed <= 0) return 'Enter a positive number';
            return null;
          },
    ),
  );
}

Widget _dateField(
  BuildContext context,
  TextEditingController controller,
  String label,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.event),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _brandRed, width: 1.4),
        ),
      ),
      onTap: () async {
        final selected = await _pickNepaliDate(context);
        if (selected != null) controller.text = selected.format();
      },
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required' : null,
    ),
  );
}

Future<NepaliDate?> _pickNepaliDate(BuildContext context) async {
  final today = NepaliDate.today();
  final selected = await picker.showMaterialDatePicker(
    context: context,
    initialDate: picker.NepaliDateTime(today.year, today.month, today.day),
    firstDate: picker.NepaliDateTime(NepaliDate.pickerFirstYear, 1, 1),
    lastDate: picker.NepaliDateTime(NepaliDate.pickerLastYear, 12, 30),
    helpText: 'Select Nepali Date',
  );
  if (selected == null) return null;
  return NepaliDate(year: selected.year, month: selected.month, day: selected.day);
}

Future<bool> _confirm(BuildContext context, String title, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFFAFBFC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _brandRed, width: 1.4),
    ),
  );
}

String _money(double value) => 'NPR ${value.toStringAsFixed(2)}';

ButtonStyle _primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: _brandRed,
    foregroundColor: Colors.white,
    elevation: 0,
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
