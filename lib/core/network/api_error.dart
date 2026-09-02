import 'package:dio/dio.dart';

/// Ubah error jaringan jadi pesan yang layak ditampilkan ke user.
///
/// Sebelumnya beberapa layar melakukan `Text('Failed: $e')`, yang untuk
/// [DioException] mencetak URL lengkap, isi response, dan detail internal ke
/// layar. Fungsi ini mengambil pesan `{"error": "..."}` dari backend kalau ada
/// — semua handler di `backend/internal/handler/` memakai bentuk itu — dan
/// jatuh ke pesan generik kalau tidak.
String apiErrorMessage(Object error) {
  if (error is! DioException) {
    return 'Terjadi kesalahan tak terduga.';
  }

  final type = error.type;
  if (type == DioExceptionType.connectionTimeout ||
      type == DioExceptionType.sendTimeout ||
      type == DioExceptionType.receiveTimeout) {
    return 'Koneksi ke server timeout. Coba lagi.';
  }
  if (type == DioExceptionType.connectionError) {
    return 'Tidak bisa menghubungi server. Cek koneksi jaringan kamu.';
  }
  if (type == DioExceptionType.cancel) {
    return 'Permintaan dibatalkan.';
  }
  if (type == DioExceptionType.badCertificate) {
    return 'Sertifikat server tidak valid.';
  }

  final data = error.response?.data;
  if (data is Map && data['error'] is String) {
    return data['error'] as String;
  }

  final status = error.response?.statusCode;
  if (status == null) {
    return 'Tidak bisa menghubungi server.';
  }
  if (status == 401) {
    return 'Sesi kamu sudah berakhir. Silakan login ulang.';
  }
  if (status == 403) {
    return 'Kamu tidak punya akses ke data ini.';
  }
  if (status == 404) {
    return 'Endpoint tidak ditemukan di server (404).';
  }
  if (status == 429) {
    return 'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.';
  }
  return 'Server membalas dengan error $status.';
}

/// Ambil [String] dari body JSON secara aman.
///
/// Backend membalas objek ride apa adanya (`c.JSON(ride)`), jadi field-nya
/// mengikuti tag di `backend/internal/domain/models.go` — misalnya `id`, bukan
/// `ride_id`. Membaca dengan `as String` langsung bikin `TypeError` kalau nama
/// field-nya salah; helper ini mengembalikan `null` supaya bisa ditangani.
String? readString(Object? body, String key) {
  if (body is! Map) return null;
  final value = body[key];
  return value is String ? value : null;
}
