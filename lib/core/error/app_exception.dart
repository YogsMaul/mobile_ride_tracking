import 'package:dio/dio.dart';

/// Exception tunggal untuk error handling di seluruh app.
/// Pesan ramah user (Bahasa Indonesia) siap ditampilkan ke UI.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;

  factory AppException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException('Koneksi ke server timeout. Coba lagi.');
      case DioExceptionType.connectionError:
        return const AppException('Tidak bisa menghubungi server. Cek koneksi kamu.');
      case DioExceptionType.cancel:
        return const AppException('Permintaan dibatalkan.');
      case DioExceptionType.badCertificate:
        return const AppException('Sertifikat server tidak valid.');
      default:
        break;
    }

    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      final rawError = data['error'] as String;
      return AppException(
        _translateError(rawError),
        statusCode: error.response?.statusCode,
      );
    }

    final status = error.response?.statusCode;
    switch (status) {
      case 401:
        return AppException('Sesi berakhir. Silakan login ulang.', statusCode: status);
      case 403:
        return AppException('Kamu tidak punya akses ke fitur ini.', statusCode: status);
      case 404:
        return AppException('Data atau endpoint tidak ditemukan (404).', statusCode: status);
      case 429:
        return AppException('Terlalu banyak permintaan. Tunggu sebentar.', statusCode: status);
      default:
        return AppException(
          status != null ? 'Server error ($status).' : 'Terjadi kesalahan jaringan.',
          statusCode: status,
        );
    }
  }

  factory AppException.unknown([Object? error]) {
    return AppException(
      error != null ? 'Terjadi kesalahan: $error' : 'Terjadi kesalahan tak terduga.',
    );
  }
}

/// Translate leftover English error messages from backend/header
/// to Indonesian, so users never see raw technical English.
String _translateError(String raw) {
  final lower = raw.toLowerCase().trim();
  switch (lower) {
    case 'invalid credentials':
      return 'Email atau password salah';
    case 'invalid request body':
      return 'Format data tidak valid';
    case 'email and password are required':
      return 'Email dan password wajib diisi';
    case 'email, password, and name are required':
      return 'Email, password, dan nama wajib diisi';
    case 'invalid email format':
      return 'Format email tidak valid';
    case 'password must be at least 8 characters and contain uppercase, lowercase, and digit':
      return 'Password minimal 8 karakter, harus ada huruf besar, huruf kecil, dan angka';
    case 'email already exists':
      return 'Email sudah terdaftar';
    case 'failed to fetch user':
      return 'Gagal mengambil data pengguna';
    case 'failed to generate token':
      return 'Gagal membuat sesi login';
    case 'failed to create user':
      return 'Gagal membuat akun';
    case 'failed to hash password':
      return 'Gagal memproses password';
    case 'unauthorized':
      return 'Sesi berakhir. Silakan login ulang';
    case 'invalid or expired refresh token':
      return 'Sesi login kadaluarsa. Silakan login ulang';
    case 'refresh token service unavailable':
      return 'Layanan refresh sesi tidak tersedia';
    case 'refresh_token is required':
      return 'Refresh token wajib diisi';
    default:
      return raw; // unknown — show as-is
  }
}
