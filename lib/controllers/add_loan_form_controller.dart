import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/loan_controller.dart';
import 'package:list/models/loan.dart';
import 'package:list/utils/nepali_date_utils.dart';

class AddLoanFormController extends GetxController {
  final LoanController _loanController = Get.find<LoanController>();

  final formKey = GlobalKey<FormState>();
  final formData = <String, dynamic>{}.obs;
  final isSubmitting = false.obs;
  final showingReissueInfo = false.obs;
  final selectedNepaliDate = NepaliDate.today().obs;
  final useCustomDate = false.obs;

  void updateFormData(String key, dynamic value) {
    formData[key] = value;

    if (key == 'name' && value != null && value.toString().isNotEmpty) {
      _checkForLoanReissue(value.toString());
    }
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
    formKey.currentState?.save();
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
    } catch (e, stack) {
      print("Error while adding loan: $e\n$stack");
    } finally {
      isSubmitting.value = false;
    }

    return success;
  }

  bool _validateAllRequiredFields() {
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
        return null;
      }

      // Use a default duration of 365 days (1 year) since we're now calculating daily interest
      // The actual interest calculation will be based on actual days passed
      return Loan.withNepaliDate(
        name: formData['name'],
        nepaliDate: selectedNepaliDate.value,
        duration: 365, // Default duration - actual interest calculated daily
        interestRate: interestRate,
        type: formData['type'],
        jewelleryName: formData['jewelleryName'],
        serialNumber: formData['serialNumber'],
        phone: formData['phone'],
        address: formData['address'],
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
}
