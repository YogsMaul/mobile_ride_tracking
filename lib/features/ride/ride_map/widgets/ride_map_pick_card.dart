import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/network/service/route_service.dart';
import '../../../../core/theme/app_theme.dart';

class RideMapPickCard extends StatelessWidget {
  const RideMapPickCard({
    super.key,
    required this.pickedPoint,
    required this.pickedName,
    required this.previewRoute,
    required this.previewUnavailable,
    required this.onCancel,
    required this.onApply,
  });

  final LatLng? pickedPoint;
  final String? pickedName;
  final RideRouteResult? previewRoute;
  final bool previewUnavailable;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: pickedPoint != null
                      ? AppColors.brandSoft
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  pickedPoint != null
                      ? Icons.place_rounded
                      : Icons.touch_app_rounded,
                  color: pickedPoint != null
                      ? AppColors.brand
                      : AppColors.muted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pickedPoint != null
                          ? (pickedName ?? 'Memuat nama lokasi…')
                          : 'Mode Pilih Tujuan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      pickedPoint != null
                          ? (previewRoute != null
                                ? '${previewRoute!.distanceFormatted} • ${previewRoute!.durationFormatted}'
                                : (previewUnavailable
                                      ? 'Jalan tidak terdeteksi'
                                      : 'Menghitung rute…'))
                          : 'Ketuk sembarang titik di peta',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: previewRoute != null
                            ? AppColors.brand
                            : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    side: const BorderSide(color: AppColors.line),
                    minimumSize: const Size(0, 38),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: onCancel,
                  child: const Text('Batal', style: TextStyle(fontSize: 12.5)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    disabledBackgroundColor: AppColors.surfaceMuted,
                    disabledForegroundColor: AppColors.muted,
                    minimumSize: const Size(0, 38),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: pickedPoint != null ? onApply : null,
                  child: const Text(
                    'Jadikan Tujuan',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
