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
      return AppException(
        data['error'] as String,
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
