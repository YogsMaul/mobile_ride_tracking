import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/network/models/ride_model.dart';
import '../../../core/network/repository/ride_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';
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

  @override
  void initState() {
    super.initState();
    _restoreActiveRide();
  }

  /// Pulihkan ride planned/active dari server — misal setelah app ditutup
  /// total, provider state hilang tapi user masih member room di backend.
  Future<void> _restoreActiveRide() async {
    if (ref.read(rideStateProvider) != null) return;
    try {
      final repo = ref.read(rideRepositoryProvider);
      final rides = await repo.getMyRides(status: 'planned,active', limit: 1);
      if (rides.isEmpty || !mounted) return;
      final r = rides.first;
      ref.read(rideStateProvider.notifier).setActive(
            RideModel(id: r.id, name: r.title, status: r.status.name),
          );
    } catch (_) {
      // Offline / gagal — banner memang tidak perlu tampil.
    }
  }

  void _backToRide() {
    final ride = ref.read(rideStateProvider);
    if (ride == null) return;
    Navigator.pushNamed(context, '/ride', arguments: {
      'rideId': ride.id,
      'inviteCode': ride.inviteCode,
      'rideName': ride.name,
    });
  }

  Future<void> _createRide() async {
    final nameController = TextEditingController();
    final roomName = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Room Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Beri nama room perjalanan (opsional). Anda akan menjadi Room Master.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              autofocus: true,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Contoh: Touring Puncak, Sunmori',
                labelText: 'Nama Room',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Buat Room'),
          ),
        ],
      ),
    );

    if (roomName == null) return; // User membatalkan dialog

    setState(() => _busy = true);
    try {
      final repo = ref.read(rideRepositoryProvider);
      final ride = await repo.createRide(
        name: roomName.isNotEmpty ? roomName : null,
      );

      if (mounted) {
        final label = ride.name != null && ride.name!.isNotEmpty
            ? 'Room "${ride.name}" dibuat! Kode: ${ride.displayCode}'
            : 'Room dibuat! Kode: ${ride.displayCode}';
        AppToast.success(context, label);
      }

      _openRide(ride.id, ride.inviteCode, ride.name);
    } on AppException catch (e) {
      if (mounted) AppToast.error(context, 'Gagal membuat ride: ${e.message}');
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal membuat ride: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showJoinDialog() async {
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
      if (mounted) AppToast.error(context, 'Gagal join ride: ${e.message}');
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal join ride: $e');
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

  @override
  Widget build(BuildContext context) {
    final activeRide = ref.watch(rideStateProvider);
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
                            onTap: _busy
                                ? null
                                : (activeRide != null
                                    ? _backToRide
                                    : _createRide),
                            activeRideName: activeRide == null
                                ? null
                                : ((activeRide.name?.isNotEmpty ?? false)
                                    ? activeRide.name
                                    : 'Ride aktif ${activeRide.displayCode}'),
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
