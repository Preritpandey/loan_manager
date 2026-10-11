// controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/services/device_access_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthController extends GetxController {
  static const String _otpVerifiedKey = 'otp_verified';
  static const String _baseUrl = DeviceAccessService.baseUrl;

  final DeviceService _deviceService = DeviceService();

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
      debugPrint('[Auth] Stored OTP verified=$verified');
      await _ensureDeviceRegistered();

      // Navigate based on verification status
      await Future.delayed(Duration(seconds: 2)); // Splash screen delay

      if (verified) {
        debugPrint('[Auth] User already verified. Checking device status.');
        await _checkDeviceStatusIfAvailable();
        debugPrint('[Auth] Startup check complete. Navigating home.');
        Get.offAllNamed('/home');
      } else {
        debugPrint('[Auth] User not verified. Navigating to OTP screen.');
        Get.offAllNamed('/otp');
      }
    } on DeviceBlockedException catch (e) {
      debugPrint('[Auth] Device blocked during startup: ${e.message}');
      await _handleBlockedDevice(e.message);
    } catch (e) {
      debugPrint('[Auth] Startup auth/device check failed: $e');
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
      await _ensureDeviceRegistered();
      final headers = await _deviceService.getDeviceHeaders();
      debugPrint('[Auth] Sending OTP verify request to $_baseUrl/verify-otp');

      final response = await http.post(
        Uri.parse('$_baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json', ...headers},
        body: jsonEncode({'otp': otp}),
      );

      debugPrint(
        '[Auth] OTP verify response. '
        'status=${response.statusCode}, body=${_trimForLog(response.body)}',
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _deviceService.handleBlockedDeviceResponse(response.statusCode, data);

      if (response.statusCode == 200 && data['success'] == true) {
        // OTP verified successfully
        debugPrint('[Auth] OTP success. Registering device.');
        await _registerVerifiedDevice();
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
        debugPrint('[Auth] Device flow complete. Navigating home.');
        Get.offAllNamed('/home');
      } else {
        // OTP verification failed
        errorMessage.value = data['message'] ?? 'OTP verification failed';
        debugPrint('[Auth] OTP failed: ${errorMessage.value}');
        Get.snackbar(
          'Error',
          errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } on DeviceBlockedException catch (e) {
      debugPrint('[Auth] Device blocked during OTP/device flow: ${e.message}');
      await _handleBlockedDevice(e.message);
    } catch (e) {
      debugPrint('[Auth] OTP verify request failed: $e');
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

  Future<void> _ensureDeviceRegistered() async {
    try {
      await _deviceService.registerDevice();
    } on DeviceBlockedException {
      rethrow;
    } catch (e) {
      debugPrint('[Auth] Device registration unavailable: $e');
      // Do not lock out the app just because the registration endpoint is unreachable.
    }
  }

  Future<void> _registerVerifiedDevice() async {
    try {
      debugPrint('[Auth] Registering verified device.');
      await _deviceService.registerDevice();
      debugPrint('[Auth] Device registration call finished. Checking status.');
      await _deviceService.checkDeviceStatus();
      debugPrint('[Auth] Device status check after registration finished.');
    } on DeviceBlockedException {
      rethrow;
    } catch (e) {
      debugPrint('[Auth] Device registration/status unavailable: $e');
      // OTP remains valid even if device registration is temporarily unavailable.
    }
  }

  Future<void> _checkDeviceStatusIfAvailable() async {
    try {
      await _deviceService.checkDeviceStatus();
    } on DeviceBlockedException {
      rethrow;
    } catch (e) {
      debugPrint('[Auth] Device status check unavailable; continuing: $e');
      // Do not force OTP again just because the status endpoint is unreachable.
    }
  }

  Future<void> enforceDeviceAccess() async {
    try {
      await _deviceService.registerDevice();
      await _deviceService.checkDeviceStatus();
    } on DeviceBlockedException catch (e) {
      await _handleBlockedDevice(e.message);
    } catch (e) {
      debugPrint('[Auth] Device access enforcement unavailable: $e');
    }
  }

  Future<void> _handleBlockedDevice(String message) async {
    debugPrint('[Auth] Routing to blocked device page.');
    await _deviceService.rememberBlockedMessage(message);
    await _saveOtpVerificationStatus(false);
    isOtpVerified.value = false;
    errorMessage.value = message;
    Get.offAllNamed('/device-blocked', arguments: message);
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

  String _trimForLog(String value) {
    const maxLength = 600;
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }
}
