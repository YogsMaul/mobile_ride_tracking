import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class SecurityHelper {
  /// Cek apakah device terdeteksi sebagai emulator / virtual device.
  /// (Hanya aktif memblokir di mode non-dev / prod atau jika diaktifkan).
  static Future<bool> isEmulator() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        // isPhysicalDevice = false berarti emulator (primary check)
        final isVirtual = !androidInfo.isPhysicalDevice;

        final fingerprint = androidInfo.fingerprint.toLowerCase();
        final model = androidInfo.model.toLowerCase();
        final manufacturer = androidInfo.manufacturer.toLowerCase();
        final product = androidInfo.product.toLowerCase();
        final hardware = androidInfo.hardware.toLowerCase();
        final host = androidInfo.host.toLowerCase();

        final isMuMuEmulator =
            (host.contains('gz') && host.endsWith('-test')) ||
            (manufacturer == 'samsung' && hardware == 'samsung');

        final isBluestacks =
            host == 'build2' ||
            (host.startsWith('build') && host.length <= 8 && !host.contains('.')) ||
            fingerprint.contains('jenkins');

        final hasEmulatorSignature =
            isMuMuEmulator ||
            isBluestacks ||
            hardware == 'ranchu' ||
            hardware == 'goldfish' ||
            hardware.contains('ranchu') ||
            hardware.contains('goldfish') ||
            fingerprint.contains('generic') ||
            fingerprint.contains(':sdk_') ||
            model.contains('sdk_gphone') ||
            model.contains('android sdk') ||
            model.contains('google_sdk') ||
            model.contains('emulator') ||
            manufacturer.contains('genymotion') ||
            product.contains('sdk_gphone') ||
            product.contains('google_sdk') ||
            product.contains('emulator') ||
            product.contains('simulator') ||
            host.contains('buildbot') ||
            host.contains('android-build');

        return isVirtual || hasEmulatorSignature;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return !iosInfo.isPhysicalDevice;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking emulator security: $e');
      return false;
    }
  }
}
