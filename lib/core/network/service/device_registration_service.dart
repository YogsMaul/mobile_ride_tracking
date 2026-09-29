import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../constants/api_constants.dart';
import '../../storage/secure_storage_service.dart';

class DeviceRegistrationService {
  final SecureStorageService _storage;
  final Dio _dio;
  final DeviceInfoPlugin _deviceInfo;
  bool _isInitialized = false;
  Completer<void>? _registrationCompleter;

  DeviceRegistrationService({
    SecureStorageService? storage,
    Dio? dio,
    DeviceInfoPlugin? deviceInfo,
  })  : _storage = storage ?? const SecureStorageService(),
        _dio = dio ?? Dio(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  String _getFormattedTimestamp() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(offset.inHours.abs());
    final minutes = twoDigits(offset.inMinutes.remainder(60));
    final sign = offset.isNegative ? '-' : '+';

    final timezone = '$sign$hours:$minutes';
    final date = '${now.year}-${twoDigits(now.month)}-${twoDigits(now.day)}';
    final time =
        '${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}';

    return '${date}T$time$timezone';
  }

  String _buildCanonicalBody(Map<String, dynamic> body) {
    return jsonEncode(body).replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  String _buildInitSignature({
    required String httpMethod,
    required String endpointPath,
    required String canonicalBody,
    required String timestamp,
    required String deviceId,
    required String hmacKey,
  }) {
    final bodyHash =
        crypto.sha256.convert(utf8.encode(canonicalBody)).toString();
    final stringToSign =
        '${httpMethod.toUpperCase()}:$endpointPath:$bodyHash:$timestamp';
    final clientSecret = '$deviceId$hmacKey';
    final hmacSha512 = crypto.Hmac(crypto.sha512, utf8.encode(clientSecret));

    return hmacSha512.convert(utf8.encode(stringToSign)).toString();
  }

  Future<void> registerDeviceIfNeeded() async {
    if (_registrationCompleter != null) {
      debugPrint('[DeviceReg] Waiting for ongoing registration...');
      await _registrationCompleter!.future;
      return;
    }

    if (_isInitialized) {
      return;
    }

    final isRegistered = await _storage.getDeviceRegistered();
    if (isRegistered == 'true') {
      final existingHmac = await _storage.getHmacKey();
      if (existingHmac != null && existingHmac.isNotEmpty) {
        debugPrint('[DeviceReg] Perangkat sudah terdaftar sebelumnya.');
        _isInitialized = true;
        return;
      }
      debugPrint('[DeviceReg] device_registered=true tapi hmac_key hilang, re-registrasi...');
      await _storage.deleteDeviceRegistered();
    }

    debugPrint('[DeviceReg] Memulai proses registrasi perangkat...');
    _registrationCompleter = Completer<void>();

    try {
      await _performRegistration();
      _isInitialized = true;
      _registrationCompleter!.complete();
    } catch (e) {
      _registrationCompleter!.completeError(e);
      rethrow;
    } finally {
      _registrationCompleter = null;
    }
  }

  Future<void> _performRegistration() async {
    try {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
      final SimplePublicKey publicKey = await keyPair.extractPublicKey();

      final publicKeyBase64 = _encodeEd25519PublicKey(publicKey);

      final existingHmacKey = await _storage.getHmacKey();
      String hmacKey;
      if (existingHmacKey != null && existingHmacKey.isNotEmpty) {
        hmacKey = existingHmacKey;
      } else {
        hmacKey = _generateHmacKey();
        await _storage.saveHmacKey(hmacKey);
      }

      await _storage.savePrivateKey(base64Encode(privateKeyBytes));
      await _storage.savePublicKey(publicKeyBase64);

      String deviceId = 'unknown_device';
      String deviceName = 'Unknown Device';

      final info = await _deviceInfo.deviceInfo;
      if (info is AndroidDeviceInfo) {
        deviceId = info.id;
        deviceName = '${info.manufacturer} ${info.model}';
      } else if (info is IosDeviceInfo) {
        deviceId = info.identifierForVendor ?? 'unknown_ios';
        deviceName = info.utsname.machine;
      }

      await _storage.saveDeviceId(deviceId);

      final pemPublicKey = _toPemFormat(publicKeyBase64);
      final timestamp = _getFormattedTimestamp();
      final body = {
        'devicename': deviceName,
        'public_Key': pemPublicKey,
        'hmac_key': hmacKey,
      };

      final canonicalBody = _buildCanonicalBody(body);
      const endpointPath = '/api/v1/auth/init-device';
      final signature = _buildInitSignature(
        httpMethod: 'POST',
        endpointPath: endpointPath,
        canonicalBody: canonicalBody,
        timestamp: timestamp,
        deviceId: deviceId,
        hmacKey: hmacKey,
      );

      final url = '${ApiConstants.baseUrl}/auth/init-device';
      debugPrint('[DeviceReg] POST $url (DeviceId: $deviceId)');

      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Device-ID': deviceId,
            'X-TIMESTAMP': timestamp,
            'X-SIGNATURE': signature,
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 409) {
        debugPrint('[DeviceReg] Inisialisasi device sukses: ${response.data}');
        await _storage.saveDeviceRegistered('true');
      } else {
        throw Exception('Status ${response.statusCode}: ${response.data}');
      }
    } catch (e) {
      debugPrint('[DeviceReg] Error saat inisialisasi device: $e');
      rethrow;
    }
  }

  String _encodeEd25519PublicKey(SimplePublicKey publicKey) {
    final raw = publicKey.bytes;
    final prefix = [
      0x30, 0x2a,
      0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70,
      0x03, 0x21, 0x00,
    ];
    final x509 = Uint8List.fromList([...prefix, ...raw]);
    return base64Encode(x509);
  }

  String _toPemFormat(String base64Key) {
    return '-----BEGIN PUBLIC KEY-----\n$base64Key\n-----END PUBLIC KEY-----';
  }

  String _generateHmacKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String?> getHmacKey() async {
    final key = await _storage.getHmacKey();
    if (key == null || key.isEmpty) {
      _isInitialized = false;
      await _storage.deleteDeviceRegistered();
      try {
        await registerDeviceIfNeeded();
      } catch (e) {
        debugPrint('[DeviceReg] Re-registration error: $e');
        return null;
      }
      return await _storage.getHmacKey();
    }
    return key;
  }
}
