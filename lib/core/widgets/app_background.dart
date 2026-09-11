import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Background halaman: gradasi hijau daun lembut + dot grid + kontur
/// topografi di dua sudut (identitas peta/outdoor). Digambar vektor
/// via CustomPainter — tajam di semua resolusi, nol asset, murah
/// di-render (deterministik, tanpa animasi).
///
/// Gradasi anchor-nya `AppColors.brandSoft` (#E3F1E9) supaya tetap
/// satu palet: cukup terang agar kartu putih pop dan teks muted tetap
/// kontras, cukup hijau agar gak polos.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.child, this.spacing = 16});

  final Widget? child;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF4EC), // mint pucat — langit/udara
              AppColors.brandSoft, // #E3F1E9 — tengah, anchor palet
              Color(0xFFCFE5D5), // sage lebih dalam — dasar tanah
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _TopoBackgroundPainter(spacing: spacing),
          child: child,
        ),
      ),
    );
  }
}

class _TopoBackgroundPainter extends CustomPainter {
  _TopoBackgroundPainter({required this.spacing});

  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    // Dot grid 16px — tekstur teknikal peta, halus.
    final dot = Paint()..color = AppColors.brand.withValues(alpha: 0.10);
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }

    // Kontur topografi di dua sudut yang berseberangan.
    final stroke = Paint()
      ..color = AppColors.brand.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    _contours(
      canvas,
      Offset(-size.width * 0.08, -size.height * 0.04),
      base: size.width * 0.16,
      rings: 7,
      seed: 1.3,
      paint: stroke,
    );
    _contours(
      canvas,
      Offset(size.width * 1.06, size.height * 1.02),
      base: size.width * 0.18,
      rings: 7,
      seed: 2.1,
      paint: stroke,
    );
  }

  void _contours(
    Canvas canvas,
    Offset center, {
    required double base,
    required int rings,
    required double seed,
    required Paint paint,
  }) {
    for (var i = 0; i < rings; i++) {
      canvas.drawPath(
        _blob(center, base + i * 24.0, seed + i * 0.35),
        paint,
      );
    }
  }

  /// Blob tertutup mulus dari 8 titik dengan radius bervariasi
  /// (deterministik dari [seed], bukan random, biar repaint identik).
  Path _blob(Offset c, double r, double seed) {
    const n = 8;
    final pts = List<Offset>.generate(n, (i) {
      final a = i * math.pi * 2 / n;
      final rr = r *
          (1 + 0.16 * math.sin(a * 2 + seed) +
              0.10 * math.cos(a * 3 - seed));
      return c + Offset(math.cos(a) * rr, math.sin(a) * rr);
    });
    final path = Path()
      ..moveTo(
        (pts.last.dx + pts.first.dx) / 2,
        (pts.last.dy + pts.first.dy) / 2,
      );
    for (var i = 0; i < n; i++) {
      final p = pts[i];
      final next = pts[(i + 1) % n];
      path.quadraticBezierTo(
        p.dx,
        p.dy,
        (p.dx + next.dx) / 2,
        (p.dy + next.dy) / 2,
      );
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _TopoBackgroundPainter old) =>
      old.spacing != spacing;
}
