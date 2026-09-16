import 'package:flutter/material.dart';

import '../../../../core/network/service/route_service.dart';
import '../../../../core/theme/app_theme.dart';

class RideMapDestinationCard extends StatelessWidget {
  const RideMapDestinationCard({
    super.key,
    required this.destName,
    required this.routeResult,
    required this.isCalculatingRoute,
    required this.isHost,
    required this.onTap,
    required this.onClear,
    required this.onShowSheet,
  });

  final String? destName;
  final RideRouteResult? routeResult;
  final bool isCalculatingRoute;
  final bool isHost;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final VoidCallback onShowSheet;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (destName != null) {
          onTap();
        } else {
          onShowSheet();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.flag_rounded, color: AppColors.warn, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    destName ?? 'Belum ada tujuan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    routeResult != null
                        ? '${routeResult!.distanceFormatted} • ${routeResult!.durationFormatted} dari posisimu'
                        : (isHost
                              ? 'Ketuk untuk atur titik finish konvoi'
                              : 'Tap pin untuk lacak arah tujuan'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: routeResult != null
                          ? AppColors.brand
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (isCalculatingRoute)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isHost && destName != null)
              IconButton(
                tooltip: 'Hapus tujuan',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.warn,
                  size: 20,
                ),
                onPressed: onClear,
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
