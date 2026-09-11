import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_lifecycle.dart';
import '../../core/error/app_exception.dart';
import '../../core/network/repository/auth_repository.dart';
import '../../core/theme/app_theme.dart';
import './auth_state.dart';
import 'widgets/countdown_ring.dart';

/// Modal "Sesi kamu akan berakhir" — muncul waktu user idle > warnAfter
/// pas app resume. Countdown 30 detik; kalau lewat, auto logout. Tombol
/// Lanjutkan → silent refresh.
class IdleSessionModal extends StatefulWidget {
  const IdleSessionModal({super.key, required this.repo, required this.auth});
  final AuthRepository repo;
  final AuthState auth;

  @override
  State<IdleSessionModal> createState() => _IdleSessionModalState();
}

class _IdleSessionModalState extends State<IdleSessionModal> {
  Timer? _ticker;
  int _remaining = IdleConfig.modalCountdown.inSeconds;
  bool _resuming = false;

  int get _total => IdleConfig.modalCountdown.inSeconds;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining--);
      if (_remaining <= 0) {
        _ticker?.cancel();
        _logout();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _resume() async {
    setState(() => _resuming = true);
    try {
      final refreshToken = await widget.repo.storage.getRefreshToken();
      if (refreshToken == null) {
        _logout();
        return;
      }
      await widget.repo.refreshSession(refreshToken: refreshToken);
      widget.auth.onResumeFromIdle();
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      // Refresh gagal — biasanya backend tidak punya /auth/refresh.
      // Tampilkan pesan agar user tahu penyebab logout, bukan silent.
      debugPrint('[IdleModal] refresh gagal: ${e.message}');
      _logout();
    } catch (e) {
      debugPrint('[IdleModal] refresh gagal: $e');
      _logout();
    } finally {
      if (mounted) setState(() => _resuming = false);
    }
  }

  void _logout() {
    widget.auth.onLogout();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_remaining / _total).clamp(0.0, 1.0);
    return PopScope(
      canPop: false, // Gak bisa dismiss dengan tap di luar / back button.
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CountdownRing(progress: progress, remaining: _remaining),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sesi akan berakhir',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Kamu diam sebentar. Lanjutkan sesi biar gak ke-logout?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Otomatis logout dalam $_remaining detik',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resuming ? null : _logout,
                      child: const Text('Keluar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _resuming ? null : _resume,
                      child: _resuming
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Lanjutkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

