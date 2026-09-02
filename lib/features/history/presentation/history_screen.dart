import 'package:flutter/material.dart';

/// Halaman riwayat perjalanan.
///
/// Statusnya: **backend belum punya endpoint-nya.** Tidak ada route "ride milik
/// saya" di `backend/cmd/server/main.go:99-103` — yang ada hanya create, join,
/// get-by-id, dan start. `GET /api/v1/admin/rides` ada, tapi admin-only.
///
/// Halaman ini karena itu sengaja tidak melakukan request apa pun. Versi
/// sebelumnya memanggil `/rides/history` lalu menelan error-nya dengan
/// `catch (_) {}`, sehingga kegagalan tampil sebagai "No ride history found."
/// — user tidak bisa membedakan "belum pernah jalan" dari "fitur ini rusak".
///
/// Ada jebakan tambahan kalau nanti request-nya dihidupkan lagi apa adanya:
/// `rides.Get("/:id", ...)` di `main.go:101` menangkap `/rides/history` sebagai
/// ride dengan id `"history"`, jadi backend membalas **400 "invalid ride id"**,
/// bukan 404. Deteksi "endpoint belum ada" berbasis status 404 tidak akan
/// bekerja.
///
/// Untuk menghidupkan halaman ini:
///   1. Tambah route di backend, letakkan SEBELUM `rides.Get("/:id")` supaya
///      tidak tertelan wildcard — misal `rides.Get("/history", ...)`, atau
///      lebih aman di path lain seperti `/api/v1/me/rides`.
///   2. Tetapkan bentuk response-nya (mis. `{"rides": [ ... ]}` dengan field
///      mengikuti `internal/domain/models.go`: `id`, `status`, `started_at`,
///      `ended_at`, `created_at`). Jarak tempuh belum dihitung backend, jadi
///      jangan tampilkan `0.0 km` seolah itu fakta.
///   3. Arahkan `ApiConstants.rideHistoryEndpoint` ke path final, lalu ganti
///      body di bawah dengan list yang membaca field-field tadi.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ride History')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('Riwayat belum tersedia', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Backend belum punya endpoint riwayat perjalanan, jadi belum '
                'ada data yang bisa ditampilkan di sini.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
