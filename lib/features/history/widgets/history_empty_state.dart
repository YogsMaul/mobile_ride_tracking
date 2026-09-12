import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ilustrasi card: putih, radius 20, border hairline (spec 6).
        Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 320),
            height: 216,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: CustomPaint(painter: _EmptyRoutePainter()),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Riwayat belum tersedia',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.3,
                letterSpacing: -0.3,
                color: AppColors.ink,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            'Begitu backend punya endpoint list-my-rides, daftar '
            'perjalanan sebelumnya — jarak, kecepatan, dan rute — '
            'akan nongol di sini.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppColors.muted,
                ),
          ),
        ),
      ],
    );
  }
}

/// Konsep ilustrasi (spec 6): Clock → dashed route → finish flag.
class _EmptyRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // --- Clock (kiri) ---
    final clockCenter = Offset(cx - 88, cy - 12);
    final clockR = 26.0;
    final outline = Paint()
      ..color = AppColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawCircle(clockCenter, clockR, outline);
    // Jarum jam & menit
    canvas.drawLine(clockCenter,
        clockCenter + Offset(0, -clockR * 0.55), outline..strokeWidth = 2.2);
    canvas.drawLine(clockCenter,
        clockCenter + Offset(clockR * 0.5, clockR * 0.18), outline);

    // --- Dashed route (clock → flag) ---
    final routePaint = Paint()
      ..color = AppColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final start = Offset(clockCenter.dx + clockR + 14, cy + 6);
    final end = Offset(cx + 78, cy - 26);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        start.dx + 40,
        start.dy + 44,
        end.dx - 50,
        end.dy + 40,
        end.dx,
        end.dy,
      );
    final dashed = _dashPath(path, dashLength: 8, gapLength: 7);
    canvas.drawPath(dashed, routePaint);

    // --- Start marker (hijau) ---
    canvas.drawCircle(start, 5, Paint()..color = AppColors.brand);
    canvas.drawCircle(start, 2.2, Paint()..color = Colors.white);

    // --- Finish flag (kanan, tiang + bendera amber) ---
    final pole = end + const Offset(0, -6);
    canvas.drawLine(pole, pole + const Offset(0, 52),
        Paint()..color = AppColors.brandDark..strokeWidth = 2.6);
    final flag = Path()
      ..moveTo(pole.dx, pole.dy + 4)
      ..lineTo(pole.dx + 26, pole.dy + 12)
      ..lineTo(pole.dx, pole.dy + 22)
      ..close();
    canvas.drawPath(flag, Paint()..color = AppColors.accent);

    // --- Terrain hint: garis kontur halus bawah ---
    final contour = Paint()
      ..color = AppColors.line.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(28, size.height - 34),
      Offset(size.width - 28, size.height - 34),
      contour,
    );
    canvas.drawLine(
      Offset(48, size.height - 24),
      Offset(size.width - 48, size.height - 24),
      contour,
    );
  }

  Path _dashPath(Path source,
      {required double dashLength, required double gapLength}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var dist = 0.0;
      var draw = true;
      while (dist < metric.length) {
        final len = draw ? dashLength : gapLength;
        final next = (dist + len).clamp(0.0, metric.length);
        if (draw) {
          dest.addPath(metric.extractPath(dist, next), Offset.zero);
        }
        dist = next;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
