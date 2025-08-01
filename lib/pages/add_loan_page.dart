// features/loan/pages/add_loan_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;
    final maxWidth = isDesktop ? 800.0 : double.infinity;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Add New Loan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      Container(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 48,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loan Details',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                            ),
                            Text(
                              'Fill in the borrower and loan information',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),

                      // Personal Information Section
                      _buildSectionHeader('Personal Information', Icons.person),
                      _buildResponsiveRow(isDesktop, [
                        _buildTextField(
                          'Loan Taker Name',
                          'name',
                          icon: Icons.person_outline,
                        ),
                        _buildTextField(
                          'Phone Number',
                          'phone',
                          icon: Icons.phone_outlined,
                        ),
                      ]),
                      _buildTextField(
                        'Address',
                        'address',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 24),

                      // Loan Terms Section
                      _buildSectionHeader('Loan Terms', Icons.receipt_long),
                      _buildResponsiveRow(isDesktop, [
                        _buildTextField(
                          'Loan Amount',
                          'amountGiven',
                          isNumber: true,
                          icon: Icons.attach_money,
                          prefix: '₹',
                        ),
                        _buildTextField(
                          'Interest Rate (%)',
                          'interestRate',
                          isNumber: true,
                          icon: Icons.percent,
                        ),
                      ]),
                      _buildTextField(
                        'Duration (days)',
                        'duration',
                        isNumber: true,
                        icon: Icons.calendar_today_outlined,
                      ),

                      const SizedBox(height: 24),

                      // Collateral Information Section
                      _buildSectionHeader(
                        'Collateral Information',
                        Icons.diamond,
                      ),
                      _buildResponsiveRow(isDesktop, [
                        _buildDropdownField('Type', 'type', [
                          'Gold',
                          'Silver',
                        ], Icons.category_outlined),
                        _buildTextField(
                          'Jewellery Name',
                          'jewelleryName',
                          icon: Icons.diamond_outlined,
                        ),
                      ]),
                      _buildTextField(
                        'Serial Number',
                        'serialNumber',
                        icon: Icons.qr_code_outlined,
                      ),

                      const SizedBox(height: 24),

                      // Additional Information Section
                      _buildSectionHeader(
                        'Additional Information',
                        Icons.notes,
                      ),
                      _buildTextField(
                        'Description',
                        'description',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        required: false,
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          if (isDesktop) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Get.back(),
                                icon: const Icon(Icons.cancel_outlined),
                                label: const Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            flex: isDesktop ? 1 : 1,
                            child: ElevatedButton.icon(
                              onPressed: _handleSubmit,
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Add Loan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(child: Divider(indent: 16, color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildResponsiveRow(bool isDesktop, List<Widget> children) {
    if (isDesktop && children.length == 2) {
      return Row(
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: 16),
          Expanded(child: children[1]),
        ],
      );
    }
    return Column(children: children);
  }

  Widget _buildTextField(
    String label,
    String key, {
    bool isNumber = false,
    IconData? icon,
    String? prefix,
    int maxLines = 1,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.blue[700]) : null,
          prefixText: prefix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        inputFormatters: isNumber
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : null,
        onSaved: (value) => data[key] = value,
        validator: (value) {
          if (!required) return null;
          if (value == null || value.isEmpty) {
            return '$label is required';
          }
          if (isNumber && double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String key,
    List<String> options,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: options.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (value) => data[key] = value,
        onSaved: (value) => data[key] = value,
        validator: (value) =>
            value == null || value.isEmpty ? '$label is required' : null,
      ),
    );
  }

  void _handleSubmit() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      try {
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
            description: data['description'] ?? '',
            amountGiven: double.parse(data['amountGiven']),
          ),
        );

        // Show success message
        Get.snackbar(
          'Success',
          'Loan added successfully',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );

        Get.back();
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to add loan. Please check your input.',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          icon: const Icon(Icons.error, color: Colors.red),
        );
      }
    }
  }
}

// // features/loan/pages/add_loan_page.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:list/controllers/loan_controller.dart';
// import 'package:list/models/loan.dart';

// class AddLoanPage extends StatelessWidget {
//   final controller = Get.find<LoanController>();
//   final formKey = GlobalKey<FormState>();
//   final data = <String, dynamic>{};

//   AddLoanPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Add Loan')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 _buildTextField('Loan Taker Name', 'name'),
//                 _buildTextField('Duration (days)', 'duration', isNumber: true),
//                 _buildTextField(
//                   'Interest Rate (%)',
//                   'interestRate',
//                   isNumber: true,
//                 ),
//                 _buildTextField('Gold/Silver', 'type'),
//                 _buildTextField('Jewellery Name', 'jewelleryName'),
//                 _buildTextField('Serial Number', 'serialNumber'),
//                 _buildTextField('Phone Number', 'phone'),
//                 _buildTextField('Address', 'address'),
//                 _buildTextField('Description', 'description'),
//                 _buildTextField('Loan Amount', 'amountGiven', isNumber: true),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () {
//                     if (formKey.currentState!.validate()) {
//                       formKey.currentState!.save();
//                       controller.addLoan(
//                         Loan(
//                           name: data['name'],
//                           date: DateTime.now(),
//                           duration: int.parse(data['duration']),
//                           interestRate: double.parse(data['interestRate']),
//                           type: data['type'],
//                           jewelleryName: data['jewelleryName'],
//                           serialNumber: data['serialNumber'],
//                           phone: data['phone'],
//                           address: data['address'],
//                           description: data['description'],
//                           amountGiven: double.parse(data['amountGiven']),
//                         ),
//                       );
//                       Get.back();
//                     }
//                   },
//                   child: const Text('Add Loan'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String label, String key, {bool isNumber = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: TextFormField(
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(),
//         ),
//         keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//         onSaved: (value) => data[key] = value,
//         validator: (value) =>
//             value == null || value.isEmpty ? 'Required' : null,
//       ),
//     );
//   }
// }
