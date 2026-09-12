import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({
    super.key,
    this.totalRides,
    this.totalDistanceKm,
    this.totalDuration,
  });

  /// Null = statistik belum tersedia dari backend (spec 29).
  final int? totalRides;
  final String? totalDistanceKm;
  final String? totalDuration;

  @override
  Widget build(BuildContext context) {
    final hasStats =
        totalRides != null && totalDistanceKm != null && totalDuration != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: hasStats
          ? IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      icon: Icons.route_outlined,
                      value: '$totalRides',
                      label: 'Total Ride',
                    ),
                  ),
                  const VerticalDivider(
                      width: 1, thickness: 1, color: AppColors.line),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.alt_route_rounded,
                      value: totalDistanceKm!,
                      label: 'Total Jarak',
                    ),
                  ),
                  const VerticalDivider(
                      width: 1, thickness: 1, color: AppColors.line),
                  Expanded(
                    child: _StatItem(
                      icon: Icons.schedule_outlined,
                      value: totalDuration!,
                      label: 'Durasi',
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.route_outlined,
                    color: AppColors.brand,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Belum ada statistik perjalanan.\n'
                    'Statistik akan muncul setelah kamu menyelesaikan ride.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 10.5,
                          height: 1.45,
                          color: AppColors.muted,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.brand, size: 16),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
