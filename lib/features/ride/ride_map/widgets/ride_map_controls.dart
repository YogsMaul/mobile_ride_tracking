import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class RideMapControls extends StatelessWidget {
  const RideMapControls({
    super.key,
    required this.followMe,
    this.headingMode = false,
    required this.hasDestination,
    required this.destTooltip,
    required this.onFollowMe,
    this.onToggleHeadingMode,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onShowDestination,
  });

  final bool followMe;
  final bool headingMode;
  final bool hasDestination;
  final String destTooltip;
  final VoidCallback onFollowMe;
  final VoidCallback? onToggleHeadingMode;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onShowDestination;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapFabButton(
          tooltip: headingMode
              ? 'Mode Navigasi (Putar Peta): AKTIF'
              : (followMe ? 'Ikuti Saya (Utara di Atas)' : 'Pusatkan ke Saya'),
          icon: headingMode
              ? Icons.navigation_rounded
              : (followMe
                  ? Icons.my_location_rounded
                  : Icons.location_searching_rounded),
          active: followMe || headingMode,
          onTap: onFollowMe,
        ),
        if (followMe) ...[
          const SizedBox(height: 10),
          MapFabButton(
            tooltip: headingMode
                ? 'Kunci Arah Utara'
                : 'Putar Peta Sesuai Arah Kendaraan (Navigasi)',
            icon: headingMode
                ? Icons.explore_rounded
                : Icons.explore_off_rounded,
            active: headingMode,
            onTap: onToggleHeadingMode ?? () {},
          ),
        ],
        const SizedBox(height: 10),
        MapFabButton(
          tooltip: 'Zoom in',
          icon: Icons.add_rounded,
          onTap: onZoomIn,
        ),
        const SizedBox(height: 10),
        MapFabButton(
          tooltip: 'Zoom out',
          icon: Icons.remove_rounded,
          onTap: onZoomOut,
        ),
        const SizedBox(height: 10),
        MapFabButton(
          tooltip: destTooltip,
          icon: Icons.flag_rounded,
          active: hasDestination,
          onTap: onShowDestination,
        ),
      ],
    );
  }
}

class MapFabButton extends StatelessWidget {
  const MapFabButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.active = false,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.brand : Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 20,
              color: active ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
