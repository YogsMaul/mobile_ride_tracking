# Perbaikan Kontrak API Mobile — 2026-09-02

Scope: **hanya `mobile/`**. Tidak ada satu file backend pun yang diubah.

Masalah utamanya: semua REST call dari mobile menabrak alamat yang salah karena
prefix `/api/v1` tidak pernah dipasang, dan response create/join ride dibaca
dengan nama field yang tidak ada. Jadi bukan "kadang error" — login, register,
create ride, dan join ride memang tidak pernah bisa berhasil.

## Yang diubah

### 1. `lib/core/constants/api_constants.dart` — prefix dan path

`baseUrl` sekarang `http://<host>/api/v1`, sesuai `app.Group("/api/v1")` di
`backend/cmd/server/main.go:87`. Prefix dipasang di base URL, bukan di tiap
konstanta, supaya `login_screen` dan `register_screen` yang dulu bikin `Dio`
sendiri ikut benar tanpa perlu diubah satu-satu.

`wsUrl` **sengaja tidak** ikut diberi prefix: route `/ws/rides/:id` didaftarkan
di root (`main.go:105-112`), bukan di dalam group. Ini ditulis sebagai komentar
di file supaya tidak ada yang "merapikan" lalu mematikan WebSocket.

`createRideEndpoint` diubah dari `/rides/create` (tidak pernah ada) ke `/rides`,
sesuai `rides.Post("/", ...)` di `main.go:100`.

Konstanta `leaveRideEndpoint` dihapus — tidak ada route-nya di backend dan tidak
dipakai di mana pun. Ditambahkan konstanta untuk route yang memang ada tapi belum
dipakai mobile: forgot-password, verify-otp, reset-password, me, logout, get ride
by id, start ride.

Impor `dart:io` dihapus. Ketiga cabang `if (kIsWeb)` / `if (Platform.isAndroid)`
mengembalikan string yang sama persis, jadi percabangannya tidak berguna —
sementara `dart:io` sendiri bikin target web gagal compile.

### 2. `lib/features/ride/presentation/home_screen.dart` — pembacaan response

`response.data['ride_id'] as String` diganti jadi pembacaan field `id`. Backend
membalas objek ride apa adanya (`ride_handler.go:55` dan `:126`), dan tag
JSON-nya `id` (`internal/domain/models.go:35`) — tidak ada field `ride_id` sama
sekali. Pola `as String` di atas nilai `null` melempar `TypeError` yang tidak
tertangkap, jadi sebelumnya app crash, bukan menampilkan error.

Pembacaan sekarang lewat helper `readString()` yang balik `null` kalau bentuknya
tidak sesuai, dan hasilnya diperiksa sebelum navigasi.

Invite code di-`trim()` sebelum dikirim — backend mem-parse-nya sebagai UUID
(`ride_handler.go:102`), jadi satu spasi dari paste sudah cukup bikin 400.

`TextEditingController` di dialog join sekarang di-`dispose()`.

### 3. `lib/features/history/presentation/history_screen.dart` — jujur, bukan bohong

Dulu halaman ini memanggil `/rides/history` lalu menelan kegagalannya dengan
`catch (_) {}` kosong, sehingga error tampil sebagai "No ride history found."
User tidak bisa membedakan "belum pernah jalan" dari "fitur ini rusak".

Backend tidak punya endpoint riwayat sama sekali. Yang mendekati hanya
`GET /api/v1/admin/rides`, dan itu admin-only. Jadi halaman ini sekarang tidak
melakukan request apa pun dan menampilkan keterangan bahwa endpoint-nya belum
ada, plus komentar berisi langkah persis untuk menghidupkannya nanti.

**Temuan baru saat verifikasi:** `/rides/history` ternyata **tidak** membalas
404. `rides.Get("/:id", ...)` di `main.go:101` menangkapnya sebagai ride dengan
id `"history"`, lalu `uuid.Parse` gagal, jadi backend membalas
`400 {"error":"invalid ride id"}`. Konsekuensinya dua:

* Deteksi "endpoint belum ada" berbasis status 404 tidak akan pernah bekerja di
  bawah `/rides/`.
* Kalau nanti route riwayat dibuat, daftarkan **sebelum** `/:id` (atau pakai
  path lain seperti `/api/v1/me/rides`), kalau tidak akan tertelan wildcard.

### 4. `lib/features/auth/` — login dan register

Keduanya dulu bikin `Dio(BaseOptions(baseUrl: ...))` sendiri, jadi tanpa timeout
dan tanpa interceptor. Sekarang keduanya memakai `dioClientProvider` yang sama
dengan halaman lain.

Penulisan `refresh_token` ke secure storage dihapus. Backend tidak pernah
mengeluarkan field itu — `tokenResponse` hanya berisi `access_token` dan `user`
(`auth_handler.go:56-58`). Menulis `null` ke `flutter_secure_storage` justru
menghapus key-nya, jadi baris itu murni menyesatkan.

`access_token` sekarang divalidasi dulu; kalau kosong, user dapat pesan yang
jelas alih-alih masuk ke `/home` tanpa token lalu kena 401 di semua tempat.

Controller di kedua layar sekarang di-`dispose()`.

Helper text password disamakan dengan aturan asli di
`internal/middleware/validate.go:19` — minimal 8 karakter dengan huruf besar,
huruf kecil, dan angka. Sebelumnya tidak ada petunjuk sama sekali, padahal
register akan ditolak backend.

### 5. File baru

`lib/core/network/dio_provider.dart` memegang `dioClientProvider`. Sebelumnya
provider ini dideklarasikan **dua kali** — di `home_screen.dart:6` dan
`history_screen.dart:7` — sehingga tiap halaman punya `Dio` sendiri, dan begitu
ada satu file yang mengimpor kedua screen itu sekaligus, Dart akan menolak
compile karena nama top-level-nya ambigu.

`lib/core/network/api_error.dart` berisi `apiErrorMessage()` dan `readString()`.
Sebelumnya beberapa layar melakukan `Text('Failed: $e')`, yang untuk
`DioException` mencetak URL lengkap dan isi response ke layar user.
`apiErrorMessage` mengambil pesan `{"error": "..."}` dari backend kalau ada —
semua handler di `internal/handler/` memakai bentuk itu — dan jatuh ke pesan
generik kalau tidak.

## Verifikasi URL akhir vs route backend

| Pemanggil di mobile | URL efektif | Route backend | Status |
|---|---|---|---|
| `login_screen` | `POST /api/v1/auth/login` | `main.go:92` | cocok |
| `register_screen` | `POST /api/v1/auth/register` | `main.go:91` | cocok |
| `home_screen` create | `POST /api/v1/rides` | `main.go:100` `rides.Post("/")` | cocok |
| `home_screen` join | `POST /api/v1/rides/join` | `main.go:102` | cocok |
| `ws_manager` | `ws://<host>/ws/rides/<id>` | `main.go:112` | cocok, tidak diubah |
| `dio_client` refresh | `POST /api/v1/auth/refresh` | tidak ada | tidak pernah terpanggil (lihat catatan) |
| `history_screen` | — | tidak ada | tidak dipanggil lagi |

Soal `/rides` tanpa trailing slash: `fiber.New` di `main.go:66-68` hanya
menyetel `AppName`, jadi `StrictRouting` tetap `false` (default) dan
`/api/v1/rides` cocok dengan route yang didaftarkan sebagai `/`.

Soal refresh token: `DioClient._refreshToken()` membaca `refresh_token` dari
storage dan langsung `return false` kalau `null`. Karena tidak ada satu pun
tempat yang menuliskannya, cabang itu mati — request ke `/auth/refresh` tidak
akan pernah terjadi. Kode-nya dibiarkan apa adanya (ada di `dio_client.dart`,
tidak disentuh) dan konstantanya ditandai di `api_constants.dart`.

## Yang tidak dikerjakan (sesuai kesepakatan)

* **Backend tidak disentuh** — tidak ada `/rides/history`, tidak ada refresh
  token, tidak ada perubahan rate limiter.
* **OTP tidak disentuh** — sesuai keputusan kamu, hardcode `"111111"` itu
  memang untuk development.
* Bug mobile lain yang sudah dilaporkan tapi di luar scope kali ini: backoff
  reconnect di `ws_manager.dart`, `dispose()` yang belum ada di
  `ride_map_screen.dart`, dan key izin lokasi di `Info.plist` iOS.

## Cara memastikan

Belum bisa aku jalankan sendiri — Flutter SDK tidak ada di sandbox ini, jadi
verifikasi di atas semuanya lewat pembacaan kode dan pencocokan route. Di mesin
kamu:

```bash
cd mobile
flutter analyze
flutter run
```

Urutan uji cepat: register akun baru, lihat apakah langsung masuk `/home`, tekan
Create Ride, dan pastikan kode undangan muncul di snackbar. Kalau ada yang
gagal, pesan error-nya sekarang datang dari backend (`{"error": "..."}`), jadi
langsung menunjuk penyebabnya.
