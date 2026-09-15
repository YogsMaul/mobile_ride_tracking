import 'package:flutter/material.dart';

import '../features/auth/auth_state.dart';

/// Idle thresholds. Disesuaikan agar ramah pengguna mobile ride tracking
/// (bukan mobile banking agresif), sesi tetap terjaga saat app di latar belakang.
class IdleConfig {
  /// < durasi ini = silent (gak ngapa-ngapain, token tetap aktif).
  static const Duration grace = Duration(minutes: 15);

  /// Antara grace dan hard = idle warning, munculin modal konfirmasi (30 menit).
  static const Duration warnAfter = Duration(minutes: 30);

  /// > hard = auto logout jika app ditinggal sangat lama (24 jam / 1 hari).
  static const Duration hardLogoutAfter = Duration(hours: 24);

  /// Countdown modal: waktu toleransi sebelum auto logout saat modal tampil (60 detik).
  static const Duration modalCountdown = Duration(seconds: 60);
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
