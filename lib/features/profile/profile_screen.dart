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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
                      child: ProfileHeader(),
                    ),
                    // Hero (foto + nama) dan Statistik ikut diam (fixed).
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProfileHero(
                            name: name,
                            role: role,
                            onEditName: () =>
                                _showEditNameDialog(context, ref, name),
                          ),
                          const SizedBox(height: 8),
                          const ProfileStats(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 108),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Informasi Akun',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
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
                              onTap: () =>
                                  _showEditNameDialog(context, ref, name),
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            ActionCard(
                              icon: Icons.settings_outlined,
                              title: 'Pengaturan',
                              description: 'Layar, izin lokasi, info aplikasi',
                              onTap: () =>
                                  Navigator.pushNamed(context, '/settings'),
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog "Ubah Nama" — kirim PATCH /auth/me, refresh profil, toast sukses.
  /// Controller hidup di [_EditNameDialog] (bukan lokal) supaya gak
  /// ter-dispose saat dialog masih animasi keluar.
  Future<void> _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditNameDialog(currentName: currentName),
    );
    if (saved == true && context.mounted) {
      ref.invalidate(userProfileProvider);
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

/// Dialog "Ubah Nama" — StatefulWidget dengan controller milik sendiri,
/// dispose otomatis bareng widget (bukan manual), jadi aman dari race
/// controller-used-after-dispose saat parent rebuild/invalidate.
class _EditNameDialog extends ConsumerStatefulWidget {
  final String currentName;
  const _EditNameDialog({required this.currentName});

  @override
  ConsumerState<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends ConsumerState<_EditNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentName,
  );
  var _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newName = _controller.text.trim();
    if (newName.length < 2) {
      AppToast.error(context, 'Nama minimal 2 karakter ya.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(authRepositoryProvider).updateName(newName);
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      setState(() => _isSaving = false);
      if (mounted) AppToast.error(context, e.message);
    } catch (_) {
      setState(() => _isSaving = false);
      if (mounted) AppToast.error(context, 'Gagal menyimpan nama. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Ubah Nama'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 60,
        decoration: const InputDecoration(
          labelText: 'Nama tampilan',
          hintText: 'Cth: Neko Reii',
          counterText: '',
        ),
        onSubmitted: (_) {
          if (!_isSaving) _submit();
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brand,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
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
    );
  }
}
