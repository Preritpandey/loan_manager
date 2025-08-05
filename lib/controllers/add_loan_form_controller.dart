import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';

class AddLoanFormController extends GetxController {
  final LoanController _loanController = Get.find<LoanController>();
  
  final formKey = GlobalKey<FormState>();
  final formData = <String, dynamic>{}.obs;
  final isSubmitting = false.obs;
  final showingReissueInfo = false.obs;

  void updateFormData(String key, dynamic value) {
    formData[key] = value;
    
    // If the customer name is updated, check for loan reissue
    if (key == 'name' && value != null && value.toString().isNotEmpty) {
      _checkForLoanReissue(value.toString());
    }
  }

  void _checkForLoanReissue(String customerName) {
    final collateralInfo = _loanController.getLastCollateralInfo(customerName);
    if (collateralInfo != null) {
      showingReissueInfo.value = true;
    } else {
      showingReissueInfo.value = false;
    }
  }

  void autoFillFromPreviousLoan(String customerName) {
    final collateralInfo = _loanController.getLastCollateralInfo(customerName);
    if (collateralInfo != null) {
      // Auto-fill the form with previous loan information
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

  String? validateNumberField(String? value, String fieldName, {bool required = true}) {
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
    return null; // Optional fields don't need validation
  }

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  void saveFormData() {
    formKey.currentState?.save();
  }

  Future<bool> submitForm() async {
    if (!validateForm()) {
      return false;
    }

    saveFormData();
    isSubmitting.value = true;

    try {
      // Validate all required fields
      if (!_validateAllRequiredFields()) {
        _showErrorSnackbar('Please fill in all required fields');
        return false;
      }

      // Create loan object
      final loan = _createLoanFromFormData();
      
      // Add loan through controller
      _loanController.addLoan(loan);

      _showSuccessSnackbar('Loan added successfully');
      
      // Navigate to loans page
      Get.offAllNamed('/');
      
      return true;
    } catch (e) {
      _showErrorSnackbar('Failed to add loan. Please check your input.');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  bool _validateAllRequiredFields() {
    final requiredFields = [
      'name', 'phone', 'address', 'amountGiven', 
      'interestRate', 'duration', 'type', 'jewelleryName', 'serialNumber'
    ];
    
    for (final field in requiredFields) {
      if (formData[field] == null || formData[field].toString().isEmpty) {
        return false;
      }
    }
    return true;
  }

  Loan _createLoanFromFormData() {
    return Loan(
      name: formData['name'],
      date: DateTime.now(),
      duration: int.parse(formData['duration']),
      interestRate: double.parse(formData['interestRate']),
      type: formData['type'],
      jewelleryName: formData['jewelleryName'],
      serialNumber: formData['serialNumber'],
      phone: formData['phone'],
      address: formData['address'],
      description: formData['description'] ?? '',
      amountGiven: double.parse(formData['amountGiven']),
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green[100],
      colorText: Colors.green[800],
      icon: const Icon(Icons.check_circle, color: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
      icon: const Icon(Icons.error, color: Colors.red),
    );
  }

  void resetForm() {
    formKey.currentState?.reset();
    formData.clear();
    isSubmitting.value = false;
  }

  @override
  void onClose() {
    resetForm();
    super.onClose();
  }
}