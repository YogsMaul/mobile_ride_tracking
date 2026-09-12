import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../ride_history_item.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.item, this.onTap});

  final RideHistoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _RouteThumbnail(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusBadge(status: item.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.group_outlined,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.metadata,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontSize: 11.5,
                                color: AppColors.muted,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.timeRange,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 11.5,
                                  color: AppColors.muted,
                                ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteThumbnail extends StatelessWidget {
  const _RouteThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _RouteThumbnailPainter(),
      ),
    );
  }
}

class _RouteThumbnailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Subtle terrain contours
    final contourPaint = Paint()
      ..color = AppColors.line.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final p1 = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.2,
        size.width,
        size.height * 0.6,
      );
    canvas.drawPath(p1, contourPaint);

    final p2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.9,
        size.width,
        size.height * 0.8,
      );
    canvas.drawPath(p2, contourPaint);

    // Route line (brand green)
    final routePaint = Paint()
      ..color = AppColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final route = Path()
      ..moveTo(size.width * 0.2, size.height * 0.75)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.35,
        size.width * 0.7,
        size.height * 0.7,
        size.width * 0.8,
        size.height * 0.25,
      );
    canvas.drawPath(route, routePaint);

    // Start point (green dot)
    final startPaint = Paint()..color = AppColors.brand;
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.75),
      4.5,
      startPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.75),
      2.0,
      Paint()..color = Colors.white,
    );

    // End point (amber dot)
    final endPaint = Paint()..color = AppColors.accent;
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.25),
      5.0,
      endPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.25),
      2.2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final RideStatus status;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == RideStatus.completed;
    final bg = isCompleted ? AppColors.brandSoft : AppColors.warnFill;
    final fg = isCompleted ? AppColors.brand : AppColors.warn;
    final label = isCompleted ? 'Selesai' : 'Dibatalkan';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
