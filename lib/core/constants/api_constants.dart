/// Konfigurasi endpoint backend (Go + Fiber v2).
///
/// PENTING — REST dan WebSocket punya prefix yang berbeda:
///   * REST  ada di bawah group `/api/v1`  (backend/cmd/server/main.go:87)
///   * WS    didaftarkan di root, TANPA prefix (main.go:105-112)
/// Jadi [wsUrl] sengaja tidak memakai [apiPrefix]. Jangan "dirapikan"
/// supaya seragam dengan [baseUrl] — nanti WebSocket-nya justru mati.
class ApiConstants {
  /// Host backend. Satu-satunya tempat yang perlu diubah kalau pindah server.
  ///
  /// Mode A & C (backend di Windows, DB lokal atau di server): pakai
  /// `100.76.157.57:8080` (Tailscale IP Windows) atau `localhost:8080`
  /// kalau emulator di Windows yang sama.
  /// Mode B (backend di server Tailscale): ganti ke `100.108.2.23:8080`.
  ///
  /// Catatan untuk emulator: Android emulator tidak bisa menjangkau `localhost`
  /// milik host (pakai `10.0.2.2:8080`), tapi karena di sini yang dipakai IP
  /// Tailscale, semua platform memakai host yang sama.
  static const String host = '100.76.157.57:8080';

  /// Prefix REST API, sesuai `app.Group("/api/v1")` di main.go:87.
  static const String apiPrefix = '/api/v1';

  /// Base URL untuk semua REST call — sudah termasuk `/api/v1`.
  static String get baseUrl => 'http://$host$apiPrefix';

  /// Base URL WebSocket — tanpa `/api/v1`, sesuai `app.Get("/ws/rides/:id")`.
  static String get wsUrl => 'ws://$host/ws';

  // --- Auth — main.go:90-97 ---
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String verifyOtpEndpoint = '/auth/verify-otp';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String meEndpoint = '/auth/me';
  static const String logoutEndpoint = '/auth/logout';

  // --- Rides — main.go:99-103 ---

  /// `rides.Post("/", ...)`. Fiber jalan dengan `StrictRouting: false`,
  /// jadi `/rides` dan `/rides/` sama-sama cocok.
  static const String createRideEndpoint = '/rides';
  static const String joinRideEndpoint = '/rides/join';

  static String rideDetailEndpoint(String rideId) => '/rides/$rideId';
  static String startRideEndpoint(String rideId) => '/rides/$rideId/start';

  // --- Belum ada di backend ---
  // Route berikut BELUM didaftarkan di main.go. Jangan dipakai untuk fitur
  // baru sebelum backend-nya ada, dan jangan diam-diam di-fallback ke data
  // dummy kalau gagal — tampilkan state kosong yang jujur.
  //
  //   /rides/leave  -> tidak ada sama sekali (konstanta lamanya sudah dihapus
  //                    karena tidak dipakai di mana pun)

  /// BELUM ADA DI BACKEND — sengaja tidak dipanggil dari mana pun.
  ///
  /// Hati-hati: path ini TIDAK membalas 404. `rides.Get("/:id", ...)` di
  /// main.go:101 menangkapnya sebagai ride dengan id `"history"`, jadi backend
  /// membalas `400 {"error":"invalid ride id"}`. Kalau nanti route riwayat
  /// dibuat, daftarkan sebelum `/:id` atau pakai path lain (mis. `/me/rides`).
  static const String rideHistoryEndpoint = '/rides/history';

  /// BELUM ADA DI BACKEND, dan login pun tidak pernah mengeluarkan
  /// `refresh_token`. Interceptor 401 di DioClient otomatis berhenti karena
  /// tidak ada refresh token yang tersimpan, jadi ini tidak pernah kepanggil.
  static const String refreshTokenEndpoint = '/auth/refresh';
}
