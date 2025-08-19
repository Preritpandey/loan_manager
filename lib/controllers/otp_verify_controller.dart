// controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthController extends GetxController {
  static const String _otpVerifiedKey = 'otp_verified';
  static const String _baseUrl = 'https://otp-manager-i83k.onrender.com';

  final RxBool isOtpVerified = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isCheckingStatus = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkOtpStatus();
  }

  // Check if user has already verified OTP
  Future<void> checkOtpStatus() async {
    try {
      isCheckingStatus.value = true;
      final prefs = await SharedPreferences.getInstance();
      final verified = prefs.getBool(_otpVerifiedKey) ?? false;
      isOtpVerified.value = verified;

      // Navigate based on verification status
      await Future.delayed(Duration(seconds: 2)); // Splash screen delay

      if (verified) {
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/otp');
      }
    } catch (e) {
      print('Error checking OTP status: $e');
      Get.offAllNamed('/otp'); // Default to OTP screen on error
    } finally {
      isCheckingStatus.value = false;
    }
  }

  // Verify OTP with backend
  Future<void> verifyOtp(String otp) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await http.post(
        Uri.parse('$_baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // OTP verified successfully
        await _saveOtpVerificationStatus(true);
        isOtpVerified.value = true;

        Get.snackbar(
          'Success',
          'OTP verified successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );

        // Navigate to home screen
        Get.offAllNamed('/home');
      } else {
        // OTP verification failed
        errorMessage.value = data['message'] ?? 'OTP verification failed';
        Get.snackbar(
          'Error',
          errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      errorMessage.value = 'Network error. Please check your connection.';
      Get.snackbar(
        'Error',
        errorMessage.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Save OTP verification status to local storage
  Future<void> _saveOtpVerificationStatus(bool verified) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_otpVerifiedKey, verified);
  }

  // Reset OTP verification (for testing purposes)
  Future<void> resetOtpVerification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_otpVerifiedKey);
    isOtpVerified.value = false;
    Get.offAllNamed('/otp');
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }
}
