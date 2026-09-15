import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_toast.dart';

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.name,
    required this.role,
    this.onEditName,
  });

  final String name;
  final String role;
  final VoidCallback? onEditName;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsOf(name);
    final isAdmin = role.toLowerCase() == 'admin';

    return Column(
      children: [
        // Avatar + Orbit + Decorative icons + Edit badge
        SizedBox(
          width: 132,
          height: 122,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Orbit ring with decorative icons
              const Positioned.fill(
                child: CustomPaint(
                  painter: _OrbitPainter(),
                ),
              ),
              // Inner avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.brandSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brand, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Edit badge (bottom-right)
              Positioned(
                right: 22,
                bottom: 18,
                child: Material(
                  color: AppColors.brand,
                  shape: const CircleBorder(),
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onEditName ??
                        () => AppToast.info(context, 'Edit nama segera hadir.'),
                    child: const SizedBox(
                      width: 26,
                      height: 26,
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Name
        Text(
          name,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: 6),
        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isAdmin ? const Color(0xFFFEF3E2) : AppColors.brandSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 13,
                color: isAdmin ? AppColors.accent : AppColors.brand,
              ),
              const SizedBox(width: 5),
              Text(
                role.isNotEmpty
                    ? '${role[0].toUpperCase()}${role.substring(1)}'
                    : 'User',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isAdmin ? AppColors.accent : AppColors.brand,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Rider tagline
        Text(
          '“Setiap perjalanan punya cerita.”',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 10.5,
                color: AppColors.muted,
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  String _initialsOf(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty || cleaned == '—') return 'R';
    final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'R';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = 54.0;

    // Dotted orbit ring (#BFD8CB)
    final orbitPaint = Paint()
      ..color = const Color(0xFFBFD8CB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const totalDots = 32;
    for (int i = 0; i < totalDots; i++) {
      final angle = (2 * math.pi / totalDots) * i;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      canvas.drawCircle(p, 1.2, orbitPaint..style = PaintingStyle.fill);
    }

    // 3 Decorative orbit dots (star, pin, bike)
    _drawOrbitIcon(canvas, center, r, -0.6, AppColors.accent, Icons.star_rounded);
    _drawOrbitIcon(canvas, center, r, 0.9, AppColors.brand, Icons.location_on_rounded);
    _drawOrbitIcon(canvas, center, r, 2.5, AppColors.brandDark, Icons.two_wheeler_rounded);
  }

  void _drawOrbitIcon(
    Canvas canvas,
    Offset center,
    double r,
    double angle,
    Color color,
    IconData icon,
  ) {
    final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
    canvas.drawCircle(p, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      p,
      11,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 11,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      p - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
