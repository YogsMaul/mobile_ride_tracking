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
  app.dart                          # root widget, auth gate, MaterialApp
  routes/
    app_routes.dart                 # route names + route table + AppShell
  core/
    constants/api_constants.dart    # baseUrl, wsUrl, endpoint list
    error/
      app_exception.dart            # AppException + mapping DioException → pesan ID
    network/
      dio_client.dart               # Dio + BaseOptions
      dio_provider.dart             # dioClientProvider
      interceptor/
        auth_interceptor.dart       # token attach + 401 refresh mutex
      service/
        auth_service.dart           # raw HTTP endpoint auth
        ride_service.dart           # raw HTTP endpoint rides
      repository/
        auth_repository.dart        # mapping JSON → model + save session
        ride_repository.dart        # create/join/detail ride
      models/
        user_model.dart             # UserModel, AuthResponseModel
        ride_model.dart             # RideModel (+ displayCode)
    location/
      location_service.dart
      location_provider.dart
    storage/
      secure_storage_service.dart   # satu-satunya tempat sentuh secure storage
    websocket/
      ws_manager.dart               # connect/send/stream, backoff
      ws_manager_provider.dart
    theme/
      app_colors.dart               # token warna (brand moss green)
      app_dimensions.dart           # AppRadius, AppSpacing
      app_typography.dart           # TextTheme
      app_theme.dart                # ThemeData light
    utils/
      validators.dart               # validasi email/password/required
    widgets/
      app_background.dart           # gradasi mint-sage + topografi vektor
      app_toast.dart                # toast custom muncul dari atas
      shell_scaffold.dart           # bottom nav floating 3 tab
  features/
    auth/
      auth_state.dart               # ChangeNotifier sesi + authStateProvider
      login_screen.dart             # scenic bg + card naik animasi pas keyboard
      register_screen.dart          # password strength indicator
      forgot_password_screen.dart   # wizard 3-step: email -> OTP -> reset password
      idle_session_modal.dart
      widgets/                      # countdown_ring, password_strength_bar
    ride/
      ride_state.dart               # ride aktif (RideModel?)
      home/
        home_screen.dart            # spec beranda: hero, callout, 3 action cards
        widgets/                    # header, hero_section, action_cards, join_ride_sheet
      ride_map/
        ride_map_screen.dart        # fullscreen OpenStreetMap + WS stream
        rider_location.dart         # model posisi rider
        widgets/                    # markers, invite_sheet (QR), bottom_bar
    history/
      history_screen.dart           # empty state jujur + animasi kompas
    profile/
      profile_screen.dart           # info akun + animasi orbit + logout
      widgets/profile_row.dart
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
