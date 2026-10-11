import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:list/services/device_access_service.dart';

class DeviceBlockedPage extends StatelessWidget {
  const DeviceBlockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final messageArg = Get.arguments?.toString();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<String>(
                future: DeviceAccessService().blockedMessage(),
                builder: (context, snapshot) {
                  final message =
                      messageArg ??
                      snapshot.data ??
                      'This device has been blocked. Please contact support.';

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.block,
                        size: 72,
                        color: Color.fromARGB(255, 210, 28, 34),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Device Blocked',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
