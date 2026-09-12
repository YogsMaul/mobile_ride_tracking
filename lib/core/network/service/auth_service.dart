import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';

/// Service layer untuk endpoint authentication.
///
/// Service hanya mengirimkan raw HTTP request. Mapping response JSON
/// ke domain model + storage dilakukan di `AuthRepository`.
class AuthService {
  final Dio dio;

  AuthService(this.dio);

  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await dio.post(
      ApiConstants.loginEndpoint,
      data: {'email': email, 'password': password},
    );
  }

  Future<Response> googleLogin({
    required String idToken,
  }) async {
    return await dio.post(
      ApiConstants.googleLoginEndpoint,
      data: {'id_token': idToken},
    );
  }

  Future<Response> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return await dio.post(
      ApiConstants.registerEndpoint,
      data: {'name': name, 'email': email, 'password': password},
    );
  }

  Future<Response> getMe() async {
    return await dio.get(ApiConstants.meEndpoint);
  }

  Future<Response> logout() async {
    return await dio.post(ApiConstants.logoutEndpoint);
  }

  Future<Response> forgotPassword({required String email}) async {
    return await dio.post(
      ApiConstants.forgotPasswordEndpoint,
      data: {'email': email},
    );
  }

  Future<Response> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return await dio.post(
      ApiConstants.verifyOtpEndpoint,
      data: {'email': email, 'otp': otp},
    );
  }

  Future<Response> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return await dio.post(
      ApiConstants.resetPasswordEndpoint,
      data: {'email': email, 'otp': otp, 'new_password': newPassword},
    );
  }
}
