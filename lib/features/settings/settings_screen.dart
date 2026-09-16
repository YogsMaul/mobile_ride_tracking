import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_toast.dart';
import 'settings_provider.dart';

/// Halaman Pengaturan — preferensi lokal (perangkat), bukan data akun.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '…';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  Future<void> _checkLocationPermission() async {
    final status = await Geolocator.checkPermission();
    if (!mounted) return;
    final label = switch (status) {
      LocationPermission.always => 'Selalu diizinkan',
      LocationPermission.whileInUse => 'Saat aplikasi digunakan',
      LocationPermission.denied => 'Ditolak',
      LocationPermission.deniedForever => 'Ditolak permanen',
      LocationPermission.unableToDetermine => 'Belum diketahui',
    };
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Izin Lokasi'),
        content: Text(
          'Status saat ini: $label.\n\n'
          'Tracking konvoi butuh akses lokasi "Saat aplikasi digunakan". '
          'Buka pengaturan aplikasi untuk mengubahnya?',
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
    if (go == true) {
      await Geolocator.openAppSettings();
    }
  }

  void _showAboutMap() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sumber Peta & Rute'),
        content: const SingleChildScrollView(
          child: Text(
            'Peta dasar: © kontributor OpenStreetMap (osm.org/copyright).\n\n'
            'Pencarian alamat: Nominatim © kontributor OpenStreetMap.\n\n'
            'Perhitungan rute: OSRM (Project OSRM).\n\n'
            'Proyek ini memakai layanan publik untuk pengembangan; '
            'produksi disarankan memakai penyedia mandiri sesuai '
            'kebijakan penggunaan OSM.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                'Perjalanan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              _SettingsCard(
                children: [
                  SwitchListTile(
                    value: settings.keepScreenOn,
                    onChanged: (v) {
                      ref.read(settingsProvider.notifier).setKeepScreenOn(v);
                      AppToast.success(
                        context,
                        v
                            ? 'Layar akan tetap menyala saat ride.'
                            : 'Layar akan ikut mati seperti biasa.',
                      );
                    },
                    title: const Text(
                      'Layar tetap menyala saat ride',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    subtitle: const Text(
                      'HP tidak mati saat tracking di stang motor.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    activeThumbColor: AppColors.brand,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Perangkat',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              _SettingsCard(
                children: [
                  ListTile(
                    leading: const _TileIcon(Icons.my_location_rounded),
                    title: const Text(
                      'Izin lokasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    onTap: _checkLocationPermission,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Tentang',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              _SettingsCard(
                children: [
                  ListTile(
                    leading: const _TileIcon(Icons.map_outlined),
                    title: const Text(
                      'Sumber peta & rute',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    onTap: _showAboutMap,
                  ),
                  const Divider(height: 1, indent: 52, endIndent: 14),
                  ListTile(
                    leading: const _TileIcon(Icons.info_outline_rounded),
                    title: const Text(
                      'Versi aplikasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    trailing: Text(
                      'v$_appVersion',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    onTap: () =>
                        AppToast.info(context, 'Ride Tracking v$_appVersion'),
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: AppColors.brand, size: 17),
    );
  }
}
