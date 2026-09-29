import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_environment.dart';
import '../../core/constants/api_constants.dart';

class SecurityDialog {
  static Future<void> show({
    required BuildContext context,
    required String message,
  }) async {
    final isProd =
        ApiConstants.environmentConfig.environment == AppEnvironment.prod;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade200, width: 2),
              ),
              child: Icon(
                Icons.security_rounded,
                size: 36,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Peringatan Keamanan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (isProd) {
                    if (Platform.isAndroid) {
                      await SystemNavigator.pop();
                    } else {
                      exit(0);
                    }
                  } else {
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isProd ? const Color(0xFFDC2626) : const Color(0xFF217E56),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isProd ? 'Keluar Aplikasi' : 'Saya Mengerti (Dev Mode)',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
