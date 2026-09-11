import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage_service.dart';

/// Status sesi: logged out / logged in / idle warning (perlu konfirmasi user).
enum AuthStatus { loggedOut, loggedIn, idleWarning }

/// State singleton untuk auth. Dipakai oleh router (app.dart) buat decide
/// halaman mana yang ditampilkan, dan oleh widget idle-modal buat show.
class AuthState extends ChangeNotifier {
  AuthStatus _status = AuthStatus.loggedOut;
  bool _idleModalOpen = false;
  final SecureStorageService _storage;

  AuthState([SecureStorageService? storage])
      : _storage = storage ?? const SecureStorageService();

  AuthStatus get status => _status;
  bool get idleModalOpen => _idleModalOpen;

  /// Dipanggil sekali saat app start — restore dari secure storage.
  /// Kalau ada access_token, anggap logged in; kalau tidak, logged out.
  Future<void> bootstrap() async {
    final token = await _storage.getAccessToken();
    _set(token != null ? AuthStatus.loggedIn : AuthStatus.loggedOut);
  }

  /// Dipanggil setelah login sukses.
  void onLoginSuccess() => _set(AuthStatus.loggedIn);

  /// Dipanggil setelah logout manual / refresh gagal / idle terlalu lama.
  Future<void> onLogout() async {
    await _storage.clearAuthSession();
    _set(AuthStatus.loggedOut);
  }

  /// Idle warning: sesi sebentar lagi berakhir, user harus konfirmasi.
  void onIdleWarning() {
    if (_status == AuthStatus.loggedIn) _set(AuthStatus.idleWarning);
  }

  /// User klik "Lanjutkan" di idle modal. Set balik loggedIn; caller
  /// (modal) yang handle refresh endpoint call.
  void onResumeFromIdle() => _set(AuthStatus.loggedIn);

  /// Flag "idle modal sedang terbuka" — di-toggle oleh [_AuthGate] supaya
  /// ref.listen tidak nge-showDialog berulang kalau status idleWarning
  /// ter-fire beberapa kali sebelum modal di-dismiss.
  void markIdleModalOpen() {
    if (_idleModalOpen) return;
    _idleModalOpen = true;
  }

  void markIdleModalClosed() {
    if (!_idleModalOpen) return;
    _idleModalOpen = false;
  }

  void _set(AuthStatus s) {
    debugPrint('[AuthState] _set $s (current=$_status)');
    if (_status == s) return;
    _status = s;
    notifyListeners();
  }
}

final authStateProvider = ChangeNotifierProvider<AuthState>((ref) {
  final auth = AuthState();
  ref.onDispose(auth.dispose);
  return auth;
});
