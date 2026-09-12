import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../error/app_exception.dart';
import '../../storage/secure_storage_service.dart';
import '../dio_provider.dart';
import '../models/user_model.dart';
import '../service/auth_service.dart';

/// Contract hasil login/register yang sudah tersimpan di secure storage.
class AuthSession {
  final UserModel? user;
  const AuthSession(this.user);
}

class AuthRepository {
  final AuthService service;
  final SecureStorageService storage;

  AuthRepository(this.service, this.storage);

  Future<AuthSession> login({
    required String email,
    required String password,
  }) =>
      _authenticate(
        () => service.login(email: email, password: password),
        fallback: 'Login gagal.',
      );

  Future<AuthSession> loginWithGoogle({
    required String idToken,
  }) =>
      _authenticate(
        () => service.googleLogin(idToken: idToken),
        fallback: 'Login Google gagal.',
      );

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _authenticate(
        () => service.register(name: name, email: email, password: password),
        fallback: 'Registrasi gagal.',
      );

  Future<UserModel> getMe() async {
    try {
      final response = await service.getMe();
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Format data profil tidak dikenal.');
      }
      final user = UserModel.fromJson(data);
      if (user.id.isEmpty) {
        throw const AppException('Data profil tidak lengkap.');
      }
      return user;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  /// Request OTP forgot password. Return OTP jika server mengirimkan
  /// (mode dev/demo — lihat auth_handler.go:380).
  Future<String?> requestPasswordReset({required String email}) async {
    try {
      final response = await service.forgotPassword(email: email);
      final data = response.data;
      if (data is Map && data['otp'] is String) {
        return data['otp'] as String;
      }
      return null;
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<void> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await service.verifyOtp(email: email, otp: otp);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await service.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<void> refreshSession({required String refreshToken}) async {
    try {
      final response = await service.dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map &&
          data['access_token'] is String) {
        await storage.saveAccessToken(data['access_token'] as String);
        final newRefresh = data['refresh_token'];
        if (newRefresh is String) {
          await storage.saveRefreshToken(newRefresh);
        }
        return;
      }
      throw const AppException('Gagal memperpanjang sesi.');
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }

  Future<AuthSession> _authenticate(
    Future<Response> Function() request, {
    required String fallback,
  }) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw AppException('$fallback: respons server tidak dikenal.');
      }
      final auth = AuthResponseModel.fromJson(data);
      if (auth.accessToken.isEmpty) {
        throw AppException('$fallback: server tidak mengirim access token.');
      }
      await storage.saveAuthSession(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
        userId: auth.user?.id,
      );
      return AuthSession(auth.user);
    } on DioException catch (e) {
      throw AppException.fromDio(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider).instance;
  return AuthRepository(AuthService(dio), const SecureStorageService());
});

/// Provider profil user (GET /auth/me).
///
/// PENTING: FutureProvider meng-cache hasil — termasuk gagal. Invalidasi
/// dilakukan di `_AuthGate` (app.dart) tiap transisi ke loggedIn; tanpa itu
/// "Halo, rider" nyangkut selamanya kalau fetch pertama kena network blip.
final userProfileProvider = FutureProvider<UserModel>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getMe();
});
