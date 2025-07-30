// features/loan/pages/loan_home_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/pages/loan_tile.dart';

class LoanHomePage extends StatelessWidget {
  final LoanController controller = Get.put(LoanController());
  final searchController = TextEditingController();

  LoanHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Manager'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) => controller.loans.value = controller.search(value),
              decoration: const InputDecoration(
                hintText: 'Search by name or serial number...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() => ListView.builder(
        itemCount: controller.loans.length,
        itemBuilder: (context, index) => LoanTile(loan: controller.loans[index]),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
