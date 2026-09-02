# Ride Tracking — Mobile

Flutter app untuk ride tracking realtime. Bagian dari monorepo `ride_tracking`.

## Stack
- **Flutter** (SDK 3.x, Dart 3.x)
- **Riverpod** — state management
- **Dio** — HTTP client + interceptor
- **flutter_secure_storage** — JWT storage
- **geolocator** — GPS stream
- **flutter_map** + **OpenStreetMap** — peta
- **web_socket_channel** — realtime location broadcast
- **qr_flutter** — invite QR

## Struktur
```
lib/
  main.dart
  app.dart                          # router + theme
  core/
    constants/api_constants.dart    # baseUrl, wsUrl, endpoint list
    network/
      dio_client.dart               # interceptor + token attach
      dio_provider.dart
      api_error.dart                # apiErrorMessage() + readString()
    location/
      location_service.dart
      location_provider.dart
    websocket/
      ws_manager.dart               # connect/send/stream, backoff
      ws_manager_provider.dart
  features/
    auth/presentation/
      login_screen.dart
      register_screen.dart
    ride/presentation/
      home_screen.dart
      ride_map_screen.dart
    history/presentation/
      history_screen.dart
```

## Setup
1. Install Flutter SDK 3.x
2. `flutter pub get`
3. Konfigurasi base URL (default sudah IP Tailscale):
   ```bash
   flutter run --dart-define=API_HOST=100.76.157.57:8080
   ```
4. iOS: `cd ios && pod install`
5. Android: pastikan permission lokasi di `AndroidManifest.xml` sudah ada

## iOS config
- `NSLocationWhenInUseUsageDescription` di `Info.plist`
- ATS allow cleartext untuk dev (`100.76.157.57`)

## Android config
- `ACCESS_FINE_LOCATION` di `AndroidManifest.xml`
- Min SDK sesuai `build.gradle.kts`

## Backend contract
- REST: `/api/v1/...` (lihat `api_constants.dart`)
- WebSocket: `/ws/rides/:id` (no prefix)
- Auth: `Authorization: Bearer <access_token>` (no refresh token)

## Catatan
- Initial commit pakai Flutter default template — beberapa file platform
  (linux/macos/windows/web) masih ada tapi tidak relevan untuk target
  Android/iOS. Hapus manual bila perlu.
- `PERBAIKAN_API_2026-09-02.md` dan `TESTING.md` adalah catatan kerja
  internal, tidak di-track di git.
