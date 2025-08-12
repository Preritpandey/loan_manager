
// screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/controllers/otp_verify_controller.dart';

class SplashScreen extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security,
                size: 60,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 30),
            
            // App Name
            Text(
              'OTP Verification',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            
            // Loading indicator
            Obx(() => authController.isCheckingStatus.value
                ? CircularProgressIndicator(color: Colors.white)
                : SizedBox()),
          ],
        ),
      ),
    );
  }
}