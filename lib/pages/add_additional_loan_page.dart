// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:list/controllers/loan_controller.dart';
// import 'package:list/models/loan.dart';
// import 'package:list/pages/loan_detail_page.dart';

// class AddAdditionalLoanPage extends StatefulWidget {
//   final Loan existingLoan;

//   const AddAdditionalLoanPage({super.key, required this.existingLoan});

//   @override
//   State<AddAdditionalLoanPage> createState() => _AddAdditionalLoanPageState();
// }

// class _AddAdditionalLoanPageState extends State<AddAdditionalLoanPage> {
//   final formKey = GlobalKey<FormState>();
//   final data = <String, dynamic>{};
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     // Pre-fill with existing customer information
//     _nameController.text = widget.existingLoan.name;
//     _phoneController.text = widget.existingLoan.phone;
//     _addressController.text = widget.existingLoan.address;

//     // Set default values
//     data['name'] = widget.existingLoan.name;
//     data['phone'] = widget.existingLoan.phone;
//     data['address'] = widget.existingLoan.address;
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Additional Loan - ${widget.existingLoan.name}'),
//         backgroundColor: Colors.orange,
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildCustomerInfoCard(),
//                 const SizedBox(height: 16),
//                 _buildExistingLoansCard(),
//                 const SizedBox(height: 16),
//                 _buildLoanDetailsCard(),
//                 const SizedBox(height: 16),
//                 _buildSubmitButton(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCustomerInfoCard() {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Customer Information',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildDisabledTextField(
//               controller: _nameController,
//               label: 'Customer Name',
//               key: 'name',
//             ),
//             const SizedBox(height: 8),
//             _buildDisabledTextField(
//               controller: _phoneController,
//               label: 'Phone Number',
//               key: 'phone',
//             ),
//             const SizedBox(height: 8),
//             _buildDisabledTextField(
//               controller: _addressController,
//               label: 'Address',
//               key: 'address',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildExistingLoansCard() {
//     final controller = Get.find<LoanController>();
//     final customerLoans = controller.getLoansByCustomerName(
//       widget.existingLoan.name,
//     );
//     final totalDueAmount = controller.getTotalDueAmountForCustomer(
//       widget.existingLoan.name,
//     );

//     if (customerLoans.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Existing Loans for ${widget.existingLoan.name}',
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Total Due Amount: NPR ${totalDueAmount.toStringAsFixed(2)}',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: totalDueAmount > 0 ? Colors.red : Colors.green,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ...customerLoans
//                 .map(
//                   (loan) => Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 4.0),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             '${loan.type} - ${loan.jewelleryName}',
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                         ),
//                         Text(
//                           'NPR ${loan.amountGiven.toStringAsFixed(2)}',
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//                 .toList(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLoanDetailsCard() {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'New Loan Details',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildTextField('Duration (days)', 'duration', isNumber: true),
//             const SizedBox(height: 8),
//             _buildTextField(
//               'Interest Rate (%)',
//               'interestRate',
//               isNumber: true,
//             ),
//             const SizedBox(height: 8),
//             _buildTextField('Gold/Silver', 'type'),
//             const SizedBox(height: 8),
//             _buildTextField('Jewellery Name', 'jewelleryName'),
//             const SizedBox(height: 8),
//             _buildTextField('Serial Number', 'serialNumber'),
//             const SizedBox(height: 8),
//             _buildTextField('Description', 'description'),
//             const SizedBox(height: 8),
//             _buildTextField('Loan Amount', 'amountGiven', isNumber: true),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String label, String key, {bool isNumber = false}) {
//     return TextFormField(
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//       ),
//       keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//       onSaved: (value) => data[key] = value,
//       validator: (value) => value == null || value.isEmpty ? 'Required' : null,
//     );
//   }

//   Widget _buildDisabledTextField({
//     required TextEditingController controller,
//     required String label,
//     required String key,
//   }) {
//     return TextFormField(
//       controller: controller,
//       enabled: false,
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//         filled: true,
//         fillColor: Colors.grey[200],
//       ),
//       onSaved: (value) => data[key] = value,
//     );
//   }

//   Widget _buildSubmitButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: _submitLoan,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.orange,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//         ),
//         child: const Text(
//           'Add Additional Loan',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }

//   void _submitLoan() {
//     if (formKey.currentState!.validate()) {
//       formKey.currentState!.save();

//       final controller = Get.find<LoanController>();

//       // Check if serial number already exists
//       final existingLoan = controller.loans.firstWhereOrNull(
//         (loan) => loan.serialNumber == data['serialNumber'],
//       );

//       if (existingLoan != null) {
//         Get.snackbar(
//           'Error',
//           'Serial number already exists. Please use a different serial number.',
//           backgroundColor: Colors.red,
//           colorText: Colors.white,
//         );
//         return;
//       }

//       // Create new loan
//       final newLoan = Loan(
//         name: data['name'],
//         date: DateTime.now(),
//         duration: int.parse(data['duration']),
//         interestRate: double.parse(data['interestRate']),
//         type: data['type'],
//         jewelleryName: data['jewelleryName'],
//         serialNumber: data['serialNumber'],
//         phone: data['phone'],
//         address: data['address'],
//         description: data['description'],
//         amountGiven: double.parse(data['amountGiven']),
//       );

//       controller.addLoan(newLoan);

//       Get.snackbar(
//         'Success',
//         'Additional loan added successfully',
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );

//       // Navigate to the loan details page of the newly created loan
//       Get.off(() => LoanDetailPage(loan: newLoan));
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/pages/loan_detail_page.dart';

class AddAdditionalLoanPage extends StatefulWidget {
  final Loan existingLoan;

  const AddAdditionalLoanPage({super.key, required this.existingLoan});

  @override
  State<AddAdditionalLoanPage> createState() => _AddAdditionalLoanPageState();
}

class _AddAdditionalLoanPageState extends State<AddAdditionalLoanPage> {
  final formKey = GlobalKey<FormState>();
  final data = <String, dynamic>{};
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing customer information
    _nameController.text = widget.existingLoan.name;
    _phoneController.text = widget.existingLoan.phone;
    _addressController.text = widget.existingLoan.address;

    // Set default values
    data['name'] = widget.existingLoan.name;
    data['phone'] = widget.existingLoan.phone;
    data['address'] = widget.existingLoan.address;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Additional Loan - ${widget.existingLoan.name}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomerInfoCard(),
                const SizedBox(height: 16),
                _buildExistingLoansCard(),
                const SizedBox(height: 16),
                _buildLoanDetailsCard(),
                const SizedBox(height: 16),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            _buildDisabledTextField(
              controller: _nameController,
              label: 'Customer Name',
              key: 'name',
            ),
            const SizedBox(height: 8),
            _buildDisabledTextField(
              controller: _phoneController,
              label: 'Phone Number',
              key: 'phone',
            ),
            const SizedBox(height: 8),
            _buildDisabledTextField(
              controller: _addressController,
              label: 'Address',
              key: 'address',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingLoansCard() {
    final controller = Get.find<LoanController>();
    final customerLoans = controller.getLoansByCustomerName(
      widget.existingLoan.name,
    );
    final totalDueAmount = controller.getTotalDueAmountForCustomer(
      widget.existingLoan.name,
    );

    if (customerLoans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Existing Loans for ${widget.existingLoan.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Due Amount: NPR ${totalDueAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: totalDueAmount > 0 ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            ...customerLoans
                .map(
                  (loan) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${loan.type} - ${loan.jewelleryName}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          'NPR ${loan.amountGiven.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetailsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Loan Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Duration (days)',
              'duration',
              isNumber: true,
            ), // int only
            const SizedBox(height: 8),
            _buildTextField(
              'Interest Rate (%)',
              'interestRate',
              isNumber: true,
              allowDecimal: true,
            ), // double/int
            const SizedBox(height: 8),
            _buildTextField('Gold/Silver', 'type'),
            const SizedBox(height: 8),
            _buildTextField('Jewellery Name', 'jewelleryName'),
            const SizedBox(height: 8),
            _buildTextField('Serial Number', 'serialNumber'),
            const SizedBox(height: 8),
            _buildTextField('Description', 'description'),
            const SizedBox(height: 8),
            _buildTextField(
              'Loan Amount',
              'amountGiven',
              isNumber: true,
              allowDecimal: true,
            ), // double/int
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String key, {
    bool isNumber = false,
    bool allowDecimal = false,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: isNumber
          ? (allowDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number)
          : TextInputType.text,
      inputFormatters: isNumber
          ? (allowDecimal
                ? <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ]
                : <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly])
          : null,
      onSaved: (value) => data[key] = value,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDisabledTextField({
    required TextEditingController controller,
    required String label,
    required String key,
  }) {
    return TextFormField(
      controller: controller,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      onSaved: (value) => data[key] = value,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitLoan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Add Additional Loan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _submitLoan() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      final controller = Get.find<LoanController>();

      // Check if serial number already exists
      final existingLoan = controller.loans.firstWhereOrNull(
        (loan) => loan.serialNumber == data['serialNumber'],
      );

      if (existingLoan != null) {
        Get.snackbar(
          'Error',
          'Serial number already exists. Please use a different serial number.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Safe parsing with defaults
      final duration = int.tryParse(data['duration'] ?? '') ?? 0;
      final interestRate = double.tryParse(data['interestRate'] ?? '') ?? 0.0;
      final amountGiven = double.tryParse(data['amountGiven'] ?? '') ?? 0.0;

      // Create new loan
      final newLoan = Loan(
        name: data['name'],
        date: DateTime.now(),
        duration: duration,
        interestRate: interestRate,
        type: data['type'],
        jewelleryName: data['jewelleryName'],
        serialNumber: data['serialNumber'],
        phone: data['phone'],
        address: data['address'],
        description: data['description'],
        amountGiven: amountGiven,
      );

      controller.addLoan(newLoan);

      Get.snackbar(
        'Success',
        'Additional loan added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate to the loan details page of the newly created loan
      Get.back();
    }
  }
}
