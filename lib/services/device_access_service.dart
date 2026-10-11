import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://otp-manager-i83k.onrender.com',
  );
  static const String appApiToken = String.fromEnvironment(
    'APP_API_TOKEN',
    defaultValue:
        '44164c797ad4a0b3d04f2e06008ef0ad04a74eff25fab55a184547e820020485',
  );

  static const _deviceIdKey = 'deviceId';
  static const _deviceSecretKey = 'deviceSecret';
  static const _blockedMessageKey = 'deviceBlockedMessage';

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      debugPrint('[DeviceAccess] Using existing deviceId: $existing');
      return existing;
    }

    final deviceId = const Uuid().v4();
    await prefs.setString(_deviceIdKey, deviceId);
    debugPrint('[DeviceAccess] Created new deviceId: $deviceId');
    return deviceId;
  }

  Future<String?> getDeviceSecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceSecretKey);
  }

  Future<Map<String, String>> getDeviceHeaders() async {
    final deviceId = await getOrCreateDeviceId();
    final deviceSecret = await getDeviceSecret();
    debugPrint(
      '[DeviceAccess] Building device headers. '
      'deviceId=$deviceId, hasSecret=${deviceSecret != null && deviceSecret.isNotEmpty}',
    );

    return {
      'X-Device-Id': deviceId,
      if (deviceSecret != null && deviceSecret.isNotEmpty)
        'X-Device-Secret': deviceSecret,
    };
  }

  Future<Map<String, String>> deviceHeaders() => getDeviceHeaders();

  Future<void> registerDevice() async {
    final deviceId = await getOrCreateDeviceId();
    final savedSecret = await getDeviceSecret();
    final data = await _registerDeviceAttempt(deviceId: deviceId);

    if (_isAlreadyRegistered(data)) {
      if (savedSecret != null && savedSecret.isNotEmpty) {
        debugPrint(
          '[DeviceAccess] Device already registered. Retrying with saved secret.',
        );
        final retryData = await _registerDeviceAttempt(
          deviceId: deviceId,
          deviceSecret: savedSecret,
        );
        await _saveDeviceSecretFromResponse(retryData);
        return;
      }

      debugPrint(
        '[DeviceAccess] Device already registered but no saved secret exists. '
        'Clearing local registration and creating a new deviceId.',
      );
      await _clearDeviceRegistrationData();
      final newDeviceId = await getOrCreateDeviceId();
      final retryData = await _registerDeviceAttempt(deviceId: newDeviceId);
      await _saveDeviceSecretFromResponse(retryData);
      return;
    }

    await _saveDeviceSecretFromResponse(data);
  }

  Future<Map<String, dynamic>> _registerDeviceAttempt({
    required String deviceId,
    String? deviceSecret,
  }) async {
    final deviceName = await _deviceName();
    final platform = _platformName();
    debugPrint(
      '[DeviceAccess] Registering device. '
      'url=$baseUrl/api/devices/register, '
      'deviceId=$deviceId, deviceName=$deviceName, platform=$platform, '
      'hasSecret=${deviceSecret != null && deviceSecret.isNotEmpty}',
    );

    final response = await http.post(
      Uri.parse('$baseUrl/api/devices/register'),
      headers: {
        'Authorization': 'Bearer $appApiToken',
        'Content-Type': 'application/json',
        if (deviceSecret != null && deviceSecret.isNotEmpty)
          'X-Device-Secret': deviceSecret,
      },
      body: jsonEncode({
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
      }),
    );

    debugPrint(
      '[DeviceAccess] Register response. '
      'status=${response.statusCode}, body=${_trimForLog(response.body)}',
    );
    final data = _decodeBody(response.body);
    handleBlockedDeviceResponse(response.statusCode, data);

    return data;
  }

  Future<void> _saveDeviceSecretFromResponse(Map<String, dynamic> data) async {
    final deviceSecret = data['data']?['deviceSecret'];
    if (deviceSecret is String && deviceSecret.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deviceSecretKey, deviceSecret);
      debugPrint('[DeviceAccess] Saved deviceSecret from register response.');
    } else {
      debugPrint(
        '[DeviceAccess] Register response did not include deviceSecret.',
      );
    }
  }

  Future<void> checkDeviceStatus() async {
    final headers = await getDeviceHeaders();
    if (!headers.containsKey('X-Device-Secret')) {
      debugPrint('[DeviceAccess] Skipping status check: no deviceSecret yet.');
      return;
    }

    debugPrint(
      '[DeviceAccess] Checking device status. url=$baseUrl/api/devices/status',
    );
    final response = await http.get(
      Uri.parse('$baseUrl/api/devices/status'),
      headers: headers,
    );
    debugPrint(
      '[DeviceAccess] Status response. '
      'status=${response.statusCode}, body=${_trimForLog(response.body)}',
    );
    final data = _decodeBody(response.body);
    handleBlockedDeviceResponse(response.statusCode, data);

    if (_isBlockedDeviceStatus(data)) {
      final message =
          data['message']?.toString() ??
          'This device has been blocked. Please contact the administrator.';
      debugPrint('[DeviceAccess] Device status says blocked: $message');
      throw DeviceBlockedException(message);
    }
  }

  Future<void> checkStatus() => checkDeviceStatus();

  Future<void> rememberBlockedMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_blockedMessageKey, message);
  }

  Future<String> blockedMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_blockedMessageKey) ??
        'This device has been blocked. Please contact support.';
  }

  void handleBlockedDeviceResponse(int statusCode, Map<String, dynamic> data) {
    if (_isBlockedResponse(statusCode, data)) {
      final message =
          data['message']?.toString() ??
          'This device has been blocked. Please contact the administrator.';
      debugPrint('[DeviceAccess] Device blocked by API: $message');
      throw DeviceBlockedException(message);
    }
  }

  void throwIfBlocked(int statusCode, Map<String, dynamic> data) {
    handleBlockedDeviceResponse(statusCode, data);
  }

  Future<void> _clearDeviceRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_deviceSecretKey);
  }

  bool _isAlreadyRegistered(Map<String, dynamic> data) {
    return data['success'] == false &&
        data['code'] == 'DEVICE_ALREADY_REGISTERED';
  }

  bool _isBlockedResponse(int statusCode, Map<String, dynamic> data) {
    return statusCode == 403 &&
        data['success'] == false &&
        data['code'] == 'DEVICE_BLOCKED';
  }

  bool _isBlockedDeviceStatus(Map<String, dynamic> data) {
    final responseData = data['data'];
    if (responseData is! Map) {
      return false;
    }

    final device = responseData['device'];
    return device is Map && device['blocked'] == true;
  }

  String _trimForLog(String value) {
    const maxLength = 600;
    if (value.length <= maxLength) {
      return value;
    }
    return '${value.substring(0, maxLength)}...';
  }

  Map<String, dynamic> _decodeBody(String body) {
    if (body.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return {};
    }
    return {};
  }

  Future<String> _deviceName() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return '${info.manufacturer} ${info.model}'.trim();
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.name;
      }
      if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        return info.computerName;
      }
      if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        return info.computerName;
      }
      if (Platform.isLinux) {
        final info = await _deviceInfo.linuxInfo;
        return info.prettyName;
      }
    } catch (_) {
      // Fall through to a stable generic name.
    }
    return 'User Device';
  }

  String _platformName() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return Platform.operatingSystem;
  }
}

typedef DeviceAccessService = DeviceService;

class DeviceBlockedException implements Exception {
  const DeviceBlockedException(this.message);

  final String message;

  @override
  String toString() => message;
}
