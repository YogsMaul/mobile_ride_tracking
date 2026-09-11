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
  app.dart                          # router, theme, shell 3-tab
  core/
    constants/api_constants.dart    # baseUrl, wsUrl, endpoint list
    network/
      dio_client.dart               # interceptor + token attach
      dio_provider.dart
      user_profile_provider.dart
      api_error.dart                # apiErrorMessage() + readString()
    location/
      location_service.dart
      location_provider.dart
    websocket/
      ws_manager.dart               # connect/send/stream, backoff
      ws_manager_provider.dart
    theme/
      app_theme.dart                # AppColors (brand moss green), radius, spacing
    widgets/
      app_background.dart           # gradasi mint-sage + topografi vektor
      illustrations.dart            # vektor animasi (History, Profile)
      shell_scaffold.dart           # bottom nav 3 tab (Beranda, Riwayat, Profil)
  features/
    auth/presentation/
      login_screen.dart             # scenic bg + card naik animasi pas keyboard
      register_screen.dart          # password strength indicator
      idle_session_modal.dart
    ride/presentation/
      home_screen.dart              # spec beranda: hero, callout, 3 action cards
      ride_map_screen.dart          # fullscreen OpenStreetMap + WS stream
    history/presentation/
      history_screen.dart           # empty state jujur + animasi kompas
    profile/presentation/
      profile_screen.dart           # info akun + animasi orbit + logout
```

## Setup
1. Install Flutter SDK 3.x
2. `flutter pub get`
3. Konfigurasi base URL:
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

## Dokumentasi Tambahan
- `DESIGN.md`: Panduan design system, color token, hierarki layout, dan ilustrasi vektor
- `TESTING.md`: Panduan testing end-to-end (login, create, join, live tracking)
- `docs/PERBAIKAN_API_2026-09-02.md`: Catatan perbaikan kontrak API historis
