# Mobile Testing & E2E Verification Guide

## 1. Environment & Base URLs
URL otomatis menyesuaikan platform:
- **Android Emulator**: `http://10.0.2.2:8080` (API) & `ws://10.0.2.2:8080/ws` (WebSocket)
- **Windows Desktop / Web / iOS Simulator**: `http://localhost:8080` & `ws://localhost:8080/ws`

---

## 2. Running the App

### Option A: Windows Desktop (Fastest)
```powershell
cd D:\projek_besar\ride_tracking\mobile
flutter run -d windows
```

### Option B: Android Emulator
```powershell
flutter emulators --launch <emulator_id>
flutter run -d android
```

---

## 3. End-to-End Test Flow

1. **Register User**:
   - Screen: `/register`
   - Payload: `{"name": "Tester 1", "email": "rider1@example.com", "password": "password123"}`
   - Expected: Tokens tersimpan di `flutter_secure_storage`, redirect ke `/home`.

2. **Create Ride Session**:
   - Screen: `/home` -> Click `Create Ride`
   - Endpoint: `POST /rides/create`
   - Expected: Dapat `ride_id` & `invite_code`, masuk ke screen `/ride`.

3. **Join Ride Session (Second Device/User)**:
   - Screen: `/home` -> Click `Join Ride` -> Masukkan `invite_code` (atau scan QR code).
   - Endpoint: `POST /rides/join`
   - Expected: Masuk ke room tracking yang sama.

4. **Live GPS & WebSocket Stream**:
   - Screen: `/ride`
   - Client otomatis stream GPS koordinat tiap 10 meter atau 1-3 detik via WebSocket.
   - Map menampilkan marker posisi diri (Blue) dan rider lain (Orange).
