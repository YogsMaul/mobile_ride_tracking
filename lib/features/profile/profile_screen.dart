import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/repository/auth_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/illustrations.dart';
import '../auth/auth_state.dart';
import 'widgets/profile_row.dart';

/// Tab Profil di bottom nav. Tampilin data user dari /auth/me, kasih
/// info account (nama, email, role), tombol logout.
///
/// Gak ada edit profile, change password, atau settings lain — YAGNI
/// sampai user request. Backend udah punya /auth/change-password
/// (lihat backend/cmd/server/main.go:107) tapi belum ada UI-nya.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final name = profile?.name ?? '—';
    final email = profile?.email ?? '—';
    final role = profile?.role ?? 'user';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              const Center(child: ProfileIllustration()),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Akun kamu',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Info login dan sesi yang lagi aktif di device ini.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              ProfileRow(label: 'Nama', value: name),
              const SizedBox(height: AppSpacing.md),
              ProfileRow(label: 'Email', value: email),
              const SizedBox(height: AppSpacing.md),
              ProfileRow(label: 'Role', value: role),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warnFill,
                  foregroundColor: AppColors.warn,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => _confirmLogout(context, ref),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Keluar'),
              ),
              // Ruang aman biar tombol tak tertutup navbar floating.
              const SizedBox(height: 108),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Sesi kamu akan diakhiri. Lanjut?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warn),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      // Invalidate caches before logout.
      ref.invalidate(userProfileProvider);
      await ref.read(authStateProvider).onLogout();
    }
  }
}
