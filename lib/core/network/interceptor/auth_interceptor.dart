import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';

import '../../storage/secure_storage_service.dart';

typedef AuthExpiredCallback = void Function();
typedef AuthErrorCallback = void Function(String message);

/// Attach token + device headers (Device-ID, X-TIMESTAMP, X-SIGNATURE) + auto-refresh/replay saat 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, {this.onAuthExpired, this.onAuthError});

  final SecureStorageService _storage;
  final AuthExpiredCallback? onAuthExpired;
  final AuthErrorCallback? onAuthError;

  Completer<bool>? _refreshInFlight;

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

  @override
  void onRequest(options, handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final deviceId = await _storage.getDeviceId();
    if (deviceId != null && deviceId.isNotEmpty) {
      options.headers['Device-ID'] = deviceId;

      final hmacKey = await _storage.getHmacKey();
      if (hmacKey != null && hmacKey.isNotEmpty) {
        final timestamp = _getFormattedTimestamp();
        options.headers['X-TIMESTAMP'] = timestamp;

        String canonicalBody = '{}';
        if (options.data != null) {
          if (options.data is Map || options.data is List) {
            canonicalBody = jsonEncode(options.data).replaceAll(RegExp(r'\s+'), '').toLowerCase();
          } else if (options.data is String) {
            canonicalBody = options.data.toString().replaceAll(RegExp(r'\s+'), '').toLowerCase();
          }
        }

        final bodyHash = crypto.sha256.convert(utf8.encode(canonicalBody)).toString();
        final path = options.uri.path;
        final stringToSign = '${options.method.toUpperCase()}:$path:$bodyHash:$timestamp';
        final clientSecret = '$deviceId$hmacKey';
        final hmacSha512 = crypto.Hmac(crypto.sha512, utf8.encode(clientSecret));
        final signature = hmacSha512.convert(utf8.encode(stringToSign)).toString();

        options.headers['X-SIGNATURE'] = signature;
      }
    }

    handler.next(options);
  }

  @override
  void onError(err, handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storage.getRefreshToken();
      // Backend tidak mengeluarkan refresh_token (PERBAIKAN_API_2026-09-02.md),
      // jadi cabang tanpa refresh token yang paling sering kena.
      if (refreshToken == null) {
        onAuthError?.call('Sesi berakhir. Silakan login ulang.');
        onAuthExpired?.call();
        return handler.next(err);
      }
      final refreshed = await _refresh(err.requestOptions);
      if (refreshed) {
        return handler.resolve(await _retry(err.requestOptions));
      }
      onAuthError?.call(
        'Sesi berakhir (server tidak mendukung refresh). Silakan login ulang.',
      );
      onAuthExpired?.call();
    }
    handler.next(err);
  }

  Future<bool> _refresh(RequestOptions requestOptions) async {
    if (_refreshInFlight != null) return _refreshInFlight!.future;

    final completer = Completer<bool>();
    _refreshInFlight = completer;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        completer.complete(false);
        return false;
      }

      final dio = Dio(BaseOptions(baseUrl: requestOptions.baseUrl));
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['access_token'] is String) {
        final data = response.data as Map;
        await _storage.saveAccessToken(data['access_token'] as String);
        // Refresh token di-rotate server. Token lama hangus — kalau gak
        // di-save, request berikutnya 401 lagi.
        final newRefresh = data['refresh_token'];
        if (newRefresh is String) {
          await _storage.saveRefreshToken(newRefresh);
        }
        completer.complete(true);
        return true;
      }
      completer.complete(false);
      return false;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _storage.getAccessToken();
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    final options = Options(
      method: requestOptions.method,
      headers: headers,
    );
    final dio = Dio(BaseOptions(baseUrl: requestOptions.baseUrl));
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
