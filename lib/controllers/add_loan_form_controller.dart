import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/utils/nepali_date_utils.dart';
import 'package:list/pages/loan_detail_page.dart';

class AddLoanFormController extends GetxController {
  final LoanController _loanController = Get.find<LoanController>();

  final formKey = GlobalKey<FormState>();
  final formData = <String, dynamic>{}.obs;
  final isSubmitting = false.obs;
  final showingReissueInfo = false.obs;
  final selectedNepaliDate = NepaliDate.today().obs;
  final useCustomDate = false.obs;
  bool isAddingForExistingCustomer = false;

  void updateFormData(String key, dynamic value) {
    formData[key] = value;

    if (key == 'name' && value != null && value.toString().isNotEmpty) {
      _checkForLoanReissue(value.toString());
    }
  }

  void preFillFromArguments(Map<String, dynamic> arguments) {
    // Pre-fill customer information from arguments
    isAddingForExistingCustomer = true;
    formData['name'] = arguments['customerName'];
    formData['phone'] = arguments['phone'];
    formData['address'] = arguments['address'];
    formData['serialNumber'] = arguments['serialNumber'];

    // Don't show reissue info since we're adding for existing customer
    showingReissueInfo.value = false;
  }

  void _checkForLoanReissue(String customerName) {
    final collateralInfo = _loanController.getLastCollateralInfo(customerName);
    showingReissueInfo.value = collateralInfo != null;
  }

  void autoFillFromPreviousLoan(String customerName) {
    final collateralInfo = _loanController.getLastCollateralInfo(customerName);
    if (collateralInfo != null) {
      formData['phone'] = collateralInfo['phone'];
      formData['address'] = collateralInfo['address'];
      formData['type'] = collateralInfo['type'];
      formData['jewelleryName'] = collateralInfo['jewelleryName'];
      formData['serialNumber'] = collateralInfo['serialNumber'];

      showingReissueInfo.value = false;
      _showSuccessSnackbar('Previous loan information auto-filled');
    }
  }

  void dismissReissueInfo() {
    showingReissueInfo.value = false;
  }

  Map<String, dynamic>? getLastCollateralInfo(String customerName) {
    return _loanController.getLastCollateralInfo(customerName);
  }

  String? validateRequiredField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? validateNumberField(
    String? value,
    String fieldName, {
    bool required = true,
  }) {
    if (!required && (value == null || value.isEmpty)) return null;
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  String? validateOptionalField(String? value) {
    return null;
  }

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  void saveFormData() {
    print('🔧 Saving form data...');
    print('🔧 Current formData before save: $formData');

    // Store customer data before form save (in case disabled fields don't save)
    String? originalName = formData['name']?.toString();
    String? originalPhone = formData['phone']?.toString();
    String? originalAddress = formData['address']?.toString();

    formKey.currentState?.save();

    // Ensure pre-filled customer data is preserved for existing customers
    if (isAddingForExistingCustomer) {
      print('🔧 Preserving customer data for existing customer...');

      // Restore customer data if it was lost during form save
      if (originalName != null && originalName.isNotEmpty) {
        formData['name'] = originalName;
      }
      if (originalPhone != null && originalPhone.isNotEmpty) {
        formData['phone'] = originalPhone;
      }
      if (originalAddress != null && originalAddress.isNotEmpty) {
        formData['address'] = originalAddress;
      }

      print('🔧 FormData after save and restore: $formData');
    }
  }

  Future<bool> submitForm() async {
    if (isSubmitting.value) return false;

    if (!validateForm()) return false;

    saveFormData();
    isSubmitting.value = true;

    bool success = false;

    try {

      if (!_validateAllRequiredFields()) {
        _showErrorSnackbar('Please fill in all required fields');
        return false;
      }

      final loan = _createLoanFromFormData();
      if (loan == null) {
        _showErrorSnackbar('Invalid data. Please check your inputs.');
        return false;
      }

      _loanController.addLoan(loan);
      success = true; // Set success to true after successful loan addition

      // Navigate to the loan detail page of the newly created loan
      Get.off(() => LoanDetailPage(loan: loan));
      // Show success message
      _showSuccessSnackbar('Loan added successfully!');
    } catch (e, stack) {
      print("Error while adding loan: $e\n$stack");
      _showErrorSnackbar('Failed to add loan. Please try again.');
      success = false;
    } finally {
      isSubmitting.value = false;
    }

    return success;
  }

  bool _validateAllRequiredFields() {
    // Define customer fields that are pre-filled for existing customers
    final customerFields = ['name', 'phone', 'address'];

    final requiredFields = [
      'name',
      'phone',
      'address',
      'amountGiven',
      'interestRate',
      'type',
      'jewelleryName',
      'serialNumber',
    ];

    for (final field in requiredFields) {
      // Skip validation for customer fields if we're adding for existing customer
      // But always validate serialNumber as it represents the collateral
      if (isAddingForExistingCustomer && customerFields.contains(field)) {
        continue;
      }

      if (formData[field] == null || formData[field].toString().isEmpty) {
        return false;
      }
    }
    return true;
  }

  Loan? _createLoanFromFormData() {
    try {
      final interestStr = formData['interestRate']?.toString() ?? '';
      final amountStr = formData['amountGiven']?.toString() ?? '';

      final interestRate = double.tryParse(interestStr);
      final amountGiven = double.tryParse(amountStr);

      if (interestRate == null || amountGiven == null) {
        print('🔧 Loan creation failed: Invalid interest rate or amount');
        return null;
      }

      // For existing customers, ensure we have the customer data
      String customerName = formData['name']?.toString() ?? '';
      String customerPhone = formData['phone']?.toString() ?? '';
      String customerAddress = formData['address']?.toString() ?? '';

      // If customer data is empty but we're adding for existing customer, this is an error
      if (isAddingForExistingCustomer &&
          (customerName.isEmpty ||
              customerPhone.isEmpty ||
              customerAddress.isEmpty)) {
      
        return null;
      }



      // Use a default duration of 365 days (1 year) since we're now calculating daily interest
      // The actual interest calculation will be based on actual days passed
      return Loan.withNepaliDate(
        name: customerName,
        nepaliDate: selectedNepaliDate.value,
        duration: 365, // Default duration - actual interest calculated daily
        interestRate: interestRate,
        type: formData['type'],
        jewelleryName: formData['jewelleryName'],
        serialNumber: formData['serialNumber'],
        phone: customerPhone,
        address: customerAddress,
        description: formData['description'] ?? '',
        amountGiven: amountGiven,
      );
    } catch (e) {
      print("Loan creation failed: $e");
      return null;
    }
  }

  void _showSuccessSnackbar(String message) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.snackbar(
        'Success',
        message,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    });
  }

  void _showErrorSnackbar(String message) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.snackbar(
        'Error',
        message,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    });
  }

  void resetForm() {
    formKey.currentState?.reset();
    formData.clear();
    isSubmitting.value = false;
    selectedNepaliDate.value = NepaliDate.today();
    useCustomDate.value = false;
    isAddingForExistingCustomer = false;
  }

  void setNepaliDate(NepaliDate nepaliDate) {
    selectedNepaliDate.value = nepaliDate;
  }

  void toggleCustomDate(bool useCustom) {
    useCustomDate.value = useCustom;
    if (!useCustom) {
      selectedNepaliDate.value = NepaliDate.today();
    }
  }

  void parseCustomNepaliDate(String dateString) {
    final parsed = NepaliDate.parse(dateString);
    if (parsed != null) {
      selectedNepaliDate.value = parsed;
    }
  }

  /// Safely navigate back, checking if there are routes to pop
  void safeNavigateBack() {
    try {
      if (Get.isDialogOpen == true) {
        Get.back();
      } else if (Get.isBottomSheetOpen == true) {
        Get.back();
      } else if (Get.currentRoute != '/') {
        Get.back();
      } else {
        // If we're at the root route, just show a message
        _showSuccessSnackbar(
          'Loan added successfully! You can now add another loan.',
        );
      }
    } catch (e) {
      print('Navigation error: $e');
      // Fallback: just show success message
      _showSuccessSnackbar('Loan added successfully!');
    }
  }
}
