import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/app_exception.dart';
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
                      ProfileHero(
                        name: name,
                        role: role,
                        onEditName: () => _showEditNameDialog(context, ref, name),
                      ),
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
                        onTap: () => _showEditNameDialog(context, ref, name),
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

  /// Dialog "Ubah Nama" — kirim PATCH /auth/me, refresh profil, toast sukses.
  Future<void> _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    var isSaving = false;

    Future<void> submit(
      BuildContext ctx,
      void Function(void Function()) setDialogState,
    ) async {
      final newName = controller.text.trim();
      if (newName.length < 2) {
        AppToast.error(ctx, 'Nama minimal 2 karakter ya.');
        return;
      }
      setDialogState(() => isSaving = true);
      try {
        await ref.read(authRepositoryProvider).updateName(newName);
        ref.invalidate(userProfileProvider);
        if (ctx.mounted) Navigator.pop(ctx, true);
      } on AppException catch (e) {
        setDialogState(() => isSaving = false);
        if (ctx.mounted) {
          AppToast.error(ctx, e.message);
        }
      } catch (_) {
        setDialogState(() => isSaving = false);
        if (ctx.mounted) {
          AppToast.error(ctx, 'Gagal menyimpan nama. Coba lagi.');
        }
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Ubah Nama'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 60,
            decoration: const InputDecoration(
              labelText: 'Nama tampilan',
              hintText: 'Cth: Neko Reii',
              counterText: '',
            ),
            onSubmitted: (_) {
              if (!isSaving) submit(ctx, setDialogState);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed:
                  isSaving ? null : () => submit(ctx, setDialogState),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (saved == true && context.mounted) {
      AppToast.success(context, 'Nama berhasil diperbarui.');
    }
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
