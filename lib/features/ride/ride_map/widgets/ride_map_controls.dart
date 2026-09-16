import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class RideMapControls extends StatelessWidget {
  const RideMapControls({
    super.key,
    required this.followMe,
    required this.hasDestination,
    required this.destTooltip,
    required this.onFollowMe,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onShowDestination,
  });

  final bool followMe;
  final bool hasDestination;
  final String destTooltip;
  final VoidCallback onFollowMe;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onShowDestination;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapFabButton(
          tooltip: followMe ? 'Ikuti saya: ON' : 'Ikuti saya',
          icon: followMe
              ? Icons.my_location_rounded
              : Icons.location_searching_rounded,
          active: followMe,
          onTap: onFollowMe,
        ),
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
