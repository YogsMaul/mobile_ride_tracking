import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'interceptor/auth_interceptor.dart';

class DioClient {
  final Dio _dio;
  final SecureStorageService _storage;
  AuthExpiredCallback? onAuthExpired;
  AuthErrorCallback? onAuthError;

  DioClient([SecureStorageService? storage])
      : _storage = storage ?? const SecureStorageService(),
        _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      AuthInterceptor(
        _storage,
        onAuthExpired: () => onAuthExpired?.call(),
        onAuthError: (msg) => onAuthError?.call(msg),
      ),
    );
  }

  Dio get instance => _dio;
}
