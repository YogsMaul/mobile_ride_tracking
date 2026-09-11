import 'package:flutter/material.dart';

import '../features/auth/auth_state.dart';

/// Idle thresholds. Dipakai juga oleh idle modal (countdown).
class IdleConfig {
  /// < durasi ini = silent (gak ngapa-ngapain, token masih hidup).
  static const Duration grace = Duration(minutes: 2);

  /// Antara grace dan hard = idle warning, munculin modal konfirmasi.
  static const Duration warnAfter = Duration(minutes: 5);

  /// > hard = auto logout, sesi dianggap berakhir.
  static const Duration hardLogoutAfter = Duration(minutes: 15);

  /// Countdown modal: user punya waktu ini buat klik "Lanjutkan".
  static const Duration modalCountdown = Duration(seconds: 30);
}

/// Pasang di main.dart. Track app paused/inactive/hidden → simpan timestamp.
/// Pas resumed → hitung selisih, kasih signal ke AuthState.
class AppLifecycleObserver with WidgetsBindingObserver {
  AppLifecycleObserver(this._auth);
  final AuthState _auth;

  DateTime? _backgroundedAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _backgroundedAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.detached:
        // App bener-bener mau mati, gak peduli sesi.
        break;
    }
  }

  void _onResumed() {
    final bg = _backgroundedAt;
    _backgroundedAt = null;
    if (bg == null) return;
    if (_auth.status != AuthStatus.loggedIn) return;

    final idle = DateTime.now().difference(bg);
    if (idle >= IdleConfig.hardLogoutAfter) {
      _auth.onLogout();
    } else if (idle >= IdleConfig.warnAfter) {
      _auth.onIdleWarning();
    }
    // idle < warnAfter = silent, gak ngapa-ngapain.
  }
}
