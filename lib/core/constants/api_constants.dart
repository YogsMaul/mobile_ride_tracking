import '../../config/app_environment.dart';

/// Konfigurasi endpoint backend (Go + Fiber v2).
class ApiConstants {
  static AppEnvironmentConfig environmentConfig =
      const AppEnvironmentConfig(AppEnvironment.dev);

  static String get host => environmentConfig.host;

  /// Prefix REST API, sesuai `app.Group("/api/v1")` di main.go:87.
  static const String apiPrefix = '/api/v1';

  /// Base URL untuk semua REST call — sudah termasuk `/api/v1`.
  static String get baseUrl => environmentConfig.baseUrl;

  /// Base URL WebSocket — tanpa `/api/v1`, sesuai `app.Get("/ws/rides/:id")`.
  static String get wsUrl => environmentConfig.wsUrl;

  // --- Auth — main.go:90-97 ---
  static const String loginEndpoint = '/auth/login';
  static const String googleLoginEndpoint = '/auth/google';
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

  /// `rides.Get("/me", ...)` — list semua ride dimana user jadi member.
  /// Daftarkan SEBELUM `/:id` di main.go supaya gak tertangkap param parser.
  /// Query param opsional: ?status=completed,cancelled&limit=50&offset=0
  static const String myRidesEndpoint = '/rides/me';

  static String rideDetailEndpoint(String rideId) => '/rides/$rideId';
  static String startRideEndpoint(String rideId) => '/rides/$rideId/start';
  static String endRideEndpoint(String rideId) => '/rides/$rideId/end';
  static String cancelRideEndpoint(String rideId) => '/rides/$rideId/cancel';
  static String leaveRideEndpoint(String rideId) => '/rides/$rideId/leave';
  static String rideTrailEndpoint(String rideId) => '/rides/$rideId/trail';
  static String rideMembersEndpoint(String rideId) => '/rides/$rideId/members';
  static String rideDestinationEndpoint(String rideId) =>
      '/rides/$rideId/destination';

  // --- Belum ada di backend ---
  // Route berikut SUDAH diimplementasi di main.go (Phase 2 audit 2026-09-12).
  // Konstanta lama `rideHistoryEndpoint` diganti `myRidesEndpoint` di atas.

  /// Refresh token endpoint — backend supports rotation via Redis.
  /// Mobile interceptor belum pakai (auto-logout on 401).
  static const String refreshTokenEndpoint = '/auth/refresh';
}
