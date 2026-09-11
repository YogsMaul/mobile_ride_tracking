import 'dart:async';

import 'package:dio/dio.dart';

import '../../storage/secure_storage_service.dart';

typedef AuthExpiredCallback = void Function();
typedef AuthErrorCallback = void Function(String message);

/// Attach token + auto-refresh/replay saat 401.
///
/// Mutex refresh: kalau 2 request kena 401 barengan, hanya 1 yang
/// panggil refresh; yang lain tunggu Future yang sama, baru replay.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, {this.onAuthExpired, this.onAuthError});

  final SecureStorageService _storage;
  final AuthExpiredCallback? onAuthExpired;
  final AuthErrorCallback? onAuthError;

  Completer<bool>? _refreshInFlight;

  @override
  void onRequest(options, handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
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

      final dio = Dio(
        BaseOptions(baseUrl: requestOptions.baseUrl),
      );
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
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    final dio = Dio(
      BaseOptions(baseUrl: requestOptions.baseUrl),
    );
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
