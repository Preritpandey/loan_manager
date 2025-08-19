import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:list/controllers/add_loan_form_controller.dart';
import 'package:list/utils/nepali_date_utils.dart';

class AddLoanPage extends StatelessWidget {
  final controller = Get.put(AddLoanFormController());

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
        backgroundColor: Color.fromARGB(255, 204, 21, 27),
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
                  key: controller.formKey,
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

                      // Loan Reissue Notification
                      Obx(
                        () => controller.showingReissueInfo.value
                            ? _buildLoanReissueCard()
                            : const SizedBox.shrink(),
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

                      // Date Selection Section
                      _buildSectionHeader('Loan Date', Icons.calendar_month),
                      _buildNepaliDateSelection(),

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
                              onPressed: () async {
                                final success = await controller.submitForm();
                                if (success) {
                                  Navigator.pop(context);
                                }
                              },
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

  // ... (rest of your helper widget builders stay the same)
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
        onSaved: (value) => controller.updateFormData(key, value),
        validator: (value) {
          if (!required) return controller.validateOptionalField(value);
          if (isNumber) {
            return controller.validateNumberField(
              value,
              label,
              required: required,
            );
          }
          return controller.validateRequiredField(value, label);
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
        onChanged: (value) => controller.updateFormData(key, value),
        onSaved: (value) => controller.updateFormData(key, value),
        validator: (value) => controller.validateRequiredField(value, label),
      ),
    );
  }

  Widget _buildLoanReissueCard() {
    final customerName = controller.formData['name'] ?? '';
    final collateralInfo = controller.getLastCollateralInfo(customerName);

    if (collateralInfo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Loan Reissue Detected',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => controller.dismissReissueInfo(),
                icon: Icon(Icons.close, color: Colors.blue[700], size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'We found a previous loan for $customerName with the same collateral:',
            style: TextStyle(color: Colors.blue[800], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Collateral Type', collateralInfo['type']),
                _buildInfoRow('Jewelry Name', collateralInfo['jewelleryName']),
                _buildInfoRow('Serial Number', collateralInfo['serialNumber']),
                _buildInfoRow('Phone', collateralInfo['phone']),
                _buildInfoRow('Address', collateralInfo['address']),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      controller.autoFillFromPreviousLoan(customerName),
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Auto-fill Information'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => controller.dismissReissueInfo(),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Enter New Info'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': $value',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }

  Widget _buildNepaliDateSelection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Type Selection
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => RadioListTile<bool>(
                    title: const Text('Today\'s Date'),
                    value: false,
                    groupValue: controller.useCustomDate.value,
                    onChanged: (value) => controller.toggleCustomDate(value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Expanded(
                child: Obx(
                  () => RadioListTile<bool>(
                    title: const Text('Custom Date'),
                    value: true,
                    groupValue: controller.useCustomDate.value,
                    onChanged: (value) => controller.toggleCustomDate(value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),

          // Today's Date Display
          Obx(
            () => !controller.useCustomDate.value
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.today, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Date',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[800],
                                ),
                              ),
                              Text(
                                controller.selectedNepaliDate.value.format(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildCustomDateInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDateInput() {
    final TextEditingController dateController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_calendar, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Text(
                'Custom Nepali Date',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: dateController,
            decoration: InputDecoration(
              labelText: 'Enter date (e.g., 2082 Shrawan 10)',
              hintText: '2082 Shrawan 10',
              prefixIcon: Icon(Icons.calendar_today, color: Colors.blue[700]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              controller.parseCustomNepaliDate(value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a date';
              }
              final parsed = NepaliDate.parse(value);
              if (parsed == null) {
                return 'Please enter a valid Nepali date (e.g., 2082 Shrawan 10)';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Available months: ${NepaliDate.getMonthNames().join(', ')}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
