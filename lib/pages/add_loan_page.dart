// features/loan/pages/add_loan_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';

class AddLoanPage extends StatelessWidget {
  final controller = Get.find<LoanController>();
  final formKey = GlobalKey<FormState>();
  final data = <String, dynamic>{};

  AddLoanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Loan')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField('Loan Taker Name', 'name'),
                _buildTextField('Duration (days)', 'duration', isNumber: true),
                _buildTextField(
                  'Interest Rate (%)',
                  'interestRate',
                  isNumber: true,
                ),
                _buildTextField('Gold/Silver', 'type'),
                _buildTextField('Jewellery Name', 'jewelleryName'),
                _buildTextField('Serial Number', 'serialNumber'),
                _buildTextField('Phone Number', 'phone'),
                _buildTextField('Address', 'address'),
                _buildTextField('Description', 'description'),
                _buildTextField('Loan Amount', 'amountGiven', isNumber: true),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      controller.addLoan(
                        Loan(
                          name: data['name'],
                          date: DateTime.now(),
                          duration: int.parse(data['duration']),
                          interestRate: double.parse(data['interestRate']),
                          type: data['type'],
                          jewelleryName: data['jewelleryName'],
                          serialNumber: data['serialNumber'],
                          phone: data['phone'],
                          address: data['address'],
                          description: data['description'],
                          amountGiven: double.parse(data['amountGiven']),
                        ),
                      );
                      Get.back();
                    }
                  },
                  child: const Text('Add Loan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        onSaved: (value) => data[key] = value,
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }
}
