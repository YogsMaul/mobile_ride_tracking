import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/models/ride_model.dart';
import '../../../core/network/repository/ride_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../ride_state.dart';
import 'widgets/home_action_cards.dart';
import 'widgets/home_header.dart';
import 'widgets/home_hero_section.dart';
import 'widgets/join_ride_sheet.dart';

/// Tab Beranda — orchestration only. Widget visual ada di `widgets/`.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _busy = false;

  Future<void> _createRide() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final repo = ref.read(rideRepositoryProvider);
      final ride = await repo.createRide();

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ride.name != null && ride.name!.isNotEmpty
                      ? 'Ride "${ride.name}" dibuat! Kode: ${ride.displayCode}'
                      : 'Ride dibuat! Kode: ${ride.displayCode}',
                ),
              ),
            ],
          ),
        ),
      );

      _openRide(ride.id, ride.inviteCode, ride.name);
    } on AppException catch (e) {
      messenger.showSnackBar(_errorSnack('Gagal membuat ride', e));
    } catch (e) {
      messenger.showSnackBar(_errorSnack('Gagal membuat ride', e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showJoinDialog() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => const JoinRideSheet(),
    );

    final code = result?.trim() ?? '';
    if (code.isEmpty) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(rideRepositoryProvider);
      final ride = await repo.joinRide(inviteCode: code);
      _openRide(ride.id, ride.inviteCode, ride.name);
    } on AppException catch (e) {
      messenger.showSnackBar(_errorSnack('Gagal join ride', e));
    } catch (e) {
      messenger.showSnackBar(_errorSnack('Gagal join ride', e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openRide(String rideId, String? inviteCode, String? rideName) {
    if (!mounted) return;
    ref.read(rideStateProvider.notifier).setActive(
          RideModel(
            id: rideId,
            inviteCode: inviteCode,
            name: rideName,
          ),
        );
    Navigator.pushNamed(context, '/ride', arguments: {
      'rideId': rideId,
      'inviteCode': inviteCode,
      'rideName': rideName,
    });
  }

  Future<void> _showGpsTipDialog() {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pastikan GPS aktif'),
        content: const Text(
          'Tracking konvoi butuh sinyal GPS yang stabil. '
          'Nyalakan layanan lokasi, izinkan akses lokasi untuk aplikasi '
          'ini (pilih "Saat aplikasi digunakan"), dan hindari mode hemat '
          'daya yang membatasi GPS di latar belakang.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  SnackBar _errorSnack(String prefix, Object e) {
    final msg = e is AppException ? e.message : 'Terjadi kesalahan tak terduga.';
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text('$prefix: $msg')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background_beranda.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 10),
                          const HomeHeader(),
                          const SizedBox(height: 36),
                          const HomeHeroSection(),
                          const SizedBox(height: 20),
                          const HomeSectionTitle(),
                          const SizedBox(height: 12),
                          HomePrimaryCard(
                            onTap: _busy ? null : _createRide,
                          ),
                          const SizedBox(height: 10),
                          HomeSecondaryCard(
                            onTap: _busy ? null : _showJoinDialog,
                          ),
                          const SizedBox(height: 10),
                          HomeTipsCard(onTap: _showGpsTipDialog),
                          // Ruang aman biar konten tak tertutup navbar floating.
                          const SizedBox(height: 112),
                        ]),
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
}
