import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/repository/auth_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import '../auth/auth_state.dart';
import 'widgets/profile_cards.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_hero.dart';
import 'widgets/profile_stats.dart';

/// Tab Profil — Rider Identity + Activity Dashboard.
/// Data identitas dari /auth/me; stats null = empty copy jujur (spec 29).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final name = (profile?.name.trim().isNotEmpty ?? false)
        ? profile!.name
        : '—';
    final email = profile?.email ?? '—';
    final role = profile?.role ?? 'user';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background_profile.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ProfileHeader(),
                      const SizedBox(height: 6),
                      ProfileHero(name: name, role: role),
                      const SizedBox(height: 8),
                      const ProfileStats(),
                      const SizedBox(height: 8),
                      Text(
                        'Informasi Akun',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                      ),
                      const SizedBox(height: 5),
                      AccountInfoCard(
                        icon: Icons.person_outline_rounded,
                        label: 'Nama',
                        value: name,
                      ),
                      const SizedBox(height: 4),
                      AccountInfoCard(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: email,
                      ),
                      const SizedBox(height: 4),
                      AccountInfoCard(
                        icon: Icons.verified_user_outlined,
                        label: 'Role',
                        value: role.isNotEmpty
                            ? '${role[0].toUpperCase()}${role.substring(1)}'
                            : 'User',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lainnya',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                      ),
                      const SizedBox(height: 5),
                      ActionCard(
                        icon: Icons.settings_outlined,
                        title: 'Pengaturan',
                        description: 'Atur preferensi aplikasi',
                        onTap: () =>
                            AppToast.info(context, 'Pengaturan segera hadir.'),
                      ),
                      const SizedBox(height: 4),
                      ActionCard(
                        icon: Icons.logout_rounded,
                        title: 'Keluar',
                        description: 'Logout dari akun ini',
                        isDestructive: true,
                        onTap: () => _confirmLogout(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluar?'),
        content: const Text('Kamu akan keluar dari akun ini di device ini.'),
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
      ref.invalidate(userProfileProvider);
      await ref.read(authStateProvider).onLogout();
    }
  }
}
