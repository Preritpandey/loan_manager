import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/deposit_controller.dart';
import 'package:list/models/deposit.dart';
import 'package:list/utils/nepali_date_utils.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart' as picker;
import 'package:list/widgets/search_bar_widget.dart';

class CashDepositsPage extends StatefulWidget {
  const CashDepositsPage({super.key});

  @override
  State<CashDepositsPage> createState() => _CashDepositsPageState();
}

class _CashDepositsPageState extends State<CashDepositsPage> {
  final DepositController controller = Get.put(DepositController());
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
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
      appBar: AppBar(
        title: const Text('Cash Deposits'),
        backgroundColor: const Color.fromARGB(255, 204, 21, 27),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download All (PDF)',
            onPressed: () => controller.exportAllDepositsToPDF(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Deposit Account',
            onPressed: () => Get.to(() => const AddDepositPage()),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: maxWidth,
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final list = controller.filtered;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Summary
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cash Deposits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('Customers: ${list.length}', style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => Get.to(() => const AddDepositPage()),
                            icon: const Icon(Icons.add),
                            label: const Text('New Account'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Search bar (consistent with app style)
                  SearchBarWidget(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    isDesktop: isDesktop,
                    padding: padding,
                    onChanged: (value) {
                      controller.search(value);
                      setState(() {});
                    },
                    onSubmitted: (value) {
                      controller.search(value);
                      setState(() {});
                    },
                    onTap: () {},
                    onClear: () {
                      searchController.clear();
                      controller.clearSearch();
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 16),

                  // List
                  if (list.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                      child: const Center(child: Text('No deposit accounts found')),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final d = list[index];
                        return _depositTile(d);
                      },
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _depositTile(DepositModel d) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blueGrey[50],
              child: const Icon(Icons.person, color: Colors.black54),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.currency_rupee, size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text('NPR ${d.currentBalance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      const Text('•'),
                      const SizedBox(width: 12),
                      Text('Rate: ${d.interestRate}%', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Latest: ${d.latestTransactionDateNepali}', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Get.to(() => DepositDetailPage(depositId: d.depositId)),
              child: const Text('Statement'),
            ),
          ],
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
  final dateCtrl = TextEditingController(); // Nepali date string

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
      appBar: AppBar(
        title: const Text('Add Deposit Account'),
        backgroundColor: const Color.fromARGB(255, 204, 21, 27),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Section: Customer Information
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person, color: Colors.blue[700], size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text('Customer Information', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                  ],
                ),
              ),
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: addrCtrl,
                decoration: InputDecoration(
                  labelText: 'Address',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 16),

              // Section: Deposit Details
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.account_balance, color: Colors.green[700], size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text('Deposit Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                  ],
                ),
              ),
              TextFormField(
                controller: amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Initial Deposit Amount (NPR)',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final x = double.tryParse(v);
                  if (x == null || x <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: rateCtrl,
                decoration: InputDecoration(
                  labelText: 'Interest Rate (Yearly, display only) %',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final x = double.tryParse(v);
                  if (x == null || x < 0) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: dateCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Deposit Date (Nepali)',
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixIcon: const Icon(Icons.event),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onTap: _pickNepaliDate,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Create Deposit Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickNepaliDate() async {
    final today = NepaliDate.today();
    final initial = picker.NepaliDateTime(today.year, today.month, today.day);
    final selected = await picker.showMaterialDatePicker(
      context: context,
      initialDate: initial,
      firstDate: picker.NepaliDateTime(2000, 1, 1),
      lastDate: picker.NepaliDateTime(2200, 12, 30),
      helpText: 'Select Nepali Date',
    );
    if (selected != null) {
      final nd = NepaliDate(year: selected.year, month: selected.month, day: selected.day);
      setState(() => dateCtrl.text = nd.format());
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final initialAmount = double.parse(amountCtrl.text.trim());
    final model = DepositModel(
      name: nameCtrl.text.trim(),
      address: addrCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      interestRate: double.parse(rateCtrl.text.trim()),
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
    );
    // Add initial deposit transaction
    model.addTransaction(
      type: 'Deposit',
      amount: initialAmount,
      nepaliDateString: dateCtrl.text.trim(),
      description: 'Initial deposit',
    );

    controller.addDepositAccount(model);
    Get.back();
  }
}

class DepositDetailPage extends StatelessWidget {
  final String depositId;
  const DepositDetailPage({super.key, required this.depositId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DepositController>();
    final model = controller.getById(depositId);
    if (model == null) {
      return Scaffold(appBar: AppBar(title: const Text('Deposit Statement')), body: const Center(child: Text('Account not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Statement - ${model.name}'),
        backgroundColor: const Color.fromARGB(255, 204, 21, 27),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF',
            onPressed: () => controller.exportCustomerDepositToPDF(depositId),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context, controller, model),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: model.transactionsSortedDesc.length,
        itemBuilder: (context, index) {
          final t = model.transactionsSortedDesc[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: t.type == 'Deposit' ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.type == 'Deposit' ? Colors.green : Colors.red),
                    ),
                    child: Text(
                      t.type,
                      style: TextStyle(
                        color: t.type == 'Deposit' ? Colors.green[800] : Colors.red[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'NPR ${t.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(t.dateNepali),
                          ],
                        ),
                        Text('Bal: NPR ${t.balanceAfter.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                    if (t.description != null && t.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(t.description!),
                      ),
                  ],
                ),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, DepositController controller, DepositModel model) {
    final type = ValueNotifier<String>('Deposit');
    final amountCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: type,
                  builder: (context, v, _) => DropdownButtonFormField<String>(
                    value: v,
                    items: const [
                      DropdownMenuItem(value: 'Deposit', child: Text('Deposit')),
                      DropdownMenuItem(value: 'Withdrawal', child: Text('Withdrawal')),
                    ],
                    onChanged: (x) => type.value = x ?? 'Deposit',
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                ),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (NPR)'),
                ),
                TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Nepali Date',
                    filled: true,
                    fillColor: Colors.grey[50],
                    suffixIcon: const Icon(Icons.event),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onTap: () async {
                    final today = NepaliDate.today();
                    final initial = picker.NepaliDateTime(today.year, today.month, today.day);
                    final selected = await picker.showMaterialDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: picker.NepaliDateTime(2000, 1, 1),
                      lastDate: picker.NepaliDateTime(2200, 12, 30),
                      helpText: 'Select Nepali Date',
                    );
                    if (selected != null) {
                      final nd = NepaliDate(year: selected.year, month: selected.month, day: selected.day);
                      dateCtrl.text = nd.format();
                    }
                  },
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text.trim());
                final dateStr = dateCtrl.text.trim();
                if (amt == null || amt <= 0 || dateStr.isEmpty) return;
                controller.addTransaction(
                  depositId: model.depositId,
                  type: type.value,
                  amount: amt,
                  nepaliDate: dateStr,
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );
  }
}
