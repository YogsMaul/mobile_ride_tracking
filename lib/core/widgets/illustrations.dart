import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Kumpulan ilustrasi vektor per tab. Zero asset, digambar on the fly
/// via CustomPainter, palet [AppColors] (moss green + amber).
///
/// Beranda gak pakai ilustrasi lagi (background asset-nya sudah bawaan
/// ilustrasi rute + scene jalan). Sisa ilustrasi interaktif:
/// - History: jarum kompas bergoyang + aliran dashed menuju flag.
/// - Profile: badge identitas bernapas + satelit orbit koneksi.
///
/// Interaksi tap memberi feedback visual (chip info). Aksi utama tiap
/// halaman tetap di tombol biasa, ilustrasi hanya penguat. Hormati
/// reduce motion via MediaQuery.disableAnimations.
class HistoryIllustration extends StatefulWidget {
  const HistoryIllustration({super.key});

  @override
  State<HistoryIllustration> createState() => _HistoryIllustrationState();
}

class _HistoryIllustrationState extends State<HistoryIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  final _focus = FocusNode();
  bool _focused = false;
  double _spin = 0;
  String? _tip;
  Offset? _tipAnchor;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
    _ctrl.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _ctrl.stop();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  static Offset compassCenter(Size size) =>
      Offset(size.width * 0.36, size.height * 0.52);
  static double compassRadius(Size size) =>
      math.min(size.width, size.height) * 0.30;
  static Offset flagBase(Size size) =>
      Offset(size.width * 0.82, size.height * 0.66);

  void _showTip(String msg, Offset anchor) {
    _tipTimer?.cancel();
    setState(() {
      _tip = msg;
      _tipAnchor = anchor;
    });
    _tipTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _tip = null);
    });
  }

  void _spinCompass(Offset at) {
    setState(() => _spin += 1.0);
    _showTip('Kompas, menunggu arah ride', at);
  }

  void _onTapDown(TapDownDetails d) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final size = box.size;
    final local = d.localPosition;
    final c = compassCenter(size);
    final r = compassRadius(size);
    final f = flagBase(size);
    if ((local - c).distance < r + 14) {
      _spinCompass(c);
    } else if ((local - f).distance < 34) {
      _showTip('Finish, belum ada catatan', f);
    } else {
      setState(() => _tip = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: AspectRatio(
        aspectRatio: 14 / 10,
        child: FocusableActionDetector(
          focusNode: _focus,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                final box = context.findRenderObject() as RenderBox?;
                final at = box == null
                    ? Offset.zero
                    : Offset(box.size.width * 0.36, box.size.height * 0.52);
                _spinCompass(at);
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTapDown: reduce ? null : _onTapDown,
            child: RepaintBoundary(
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, _) => CustomPaint(
                      painter: _HistoryPainter(
                        t: _ctrl.value,
                        spin: _spin,
                        focused: _focused,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  if (_tip != null && _tipAnchor != null)
                    _TipChip(text: _tip!, anchor: _tipAnchor!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter({
    required this.t,
    required this.spin,
    required this.focused,
  });
  final double t;
  final double spin;
  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    canvas.drawRRect(card, Paint()..color = AppColors.surface);
    canvas.drawRRect(
      card,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.save();
    canvas.clipRRect(card);

    final route = Path()
      ..moveTo(size.width * 0.52, size.height * 0.78)
      ..cubicTo(
        size.width * 0.60, size.height * 0.55,
        size.width * 0.66, size.height * 0.75,
        size.width * 0.74, size.height * 0.50,
      )
      ..quadraticBezierTo(
        size.width * 0.78, size.height * 0.38,
        size.width * 0.82, size.height * 0.44,
      );
    _drawDashed(canvas, route, AppColors.brand, t);

    final base =
        _HistoryIllustrationState.flagBase(size);
    final wave = math.sin(t * 2 * math.pi) * 2.5;
    canvas.drawLine(
      base,
      base.translate(0, -34),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    final flag = Path()
      ..moveTo(base.dx, base.dy - 34)
      ..quadraticBezierTo(
        base.dx + 11, base.dy - 33 + wave, base.dx + 22, base.dy - 30 + wave,
      )
      ..lineTo(base.dx + 22, base.dy - 18 + wave)
      ..quadraticBezierTo(
        base.dx + 11, base.dy - 21 + wave, base.dx, base.dy - 20,
      )
      ..close();
    canvas.drawPath(flag, Paint()..color = AppColors.accent);
    canvas.drawCircle(base, 3, Paint()..color = AppColors.accent);

    final c = _HistoryIllustrationState.compassCenter(size);
    final r = _HistoryIllustrationState.compassRadius(size);
    canvas.drawCircle(c, r + 8, Paint()..color = AppColors.brandSoft);
    canvas.drawCircle(
      c,
      r + 8,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = AppColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final major = i % 3 == 0;
      final p1 = c +
          Offset(math.cos(a) * (r - (major ? 8 : 5)),
              math.sin(a) * (r - (major ? 8 : 5)));
      final p2 =
          c + Offset(math.cos(a) * (r - 2), math.sin(a) * (r - 2));
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = major ? AppColors.ink : AppColors.muted
          ..strokeWidth = major ? 2 : 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    final sway = math.sin(t * 2 * math.pi) * 0.21 + spin * 2 * math.pi;
    final needleLen = r - 10;
    final tipN = c +
        Offset(math.sin(sway) * needleLen, -math.cos(sway) * needleLen);
    final tipS = c -
        Offset(math.sin(sway) * (needleLen * 0.7),
            -math.cos(sway) * (needleLen * 0.7));
    canvas.drawLine(
      c,
      tipN,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      c,
      tipS,
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 3.5, Paint()..color = AppColors.ink);
    canvas.drawCircle(c, 1.6, Paint()..color = Colors.white);
    canvas.restore();

    if (focused) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          const Radius.circular(20),
        ),
        Paint()
          ..color = AppColors.brand
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawDashed(Canvas canvas, Path path, Color color, double t) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;
    const dash = 7.0;
    const gap = 6.0;
    final offset = (t * (dash + gap)) % (dash + gap);
    double d = -offset;
    while (d < m.length) {
      final start = math.max(0.0, d);
      final end = math.min(m.length, d + dash);
      if (end > start) {
        canvas.drawPath(
          m.extractPath(start, end),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
      d += dash + gap;
    }
    final flow = m.getTangentForOffset((t * m.length) % m.length);
    if (flow != null) {
      canvas.drawCircle(flow.position, 3.5, Paint()..color = color);
      canvas.drawCircle(
          flow.position, 3.5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter old) =>
      old.t != t || old.spin != spin || old.focused != focused;
}

class ProfileIllustration extends StatefulWidget {
  const ProfileIllustration({super.key});

  @override
  State<ProfileIllustration> createState() => _ProfileIllustrationState();
}

class _ProfileIllustrationState extends State<ProfileIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  final _focus = FocusNode();
  bool _focused = false;
  double _boost = 0;
  int? _activeSat;
  String? _tip;
  Offset? _tipAnchor;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
    _ctrl.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _ctrl.stop();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  static Offset centerOf(Size size) =>
      Offset(size.width * 0.5, size.height * 0.52);
  static double orbitOf(Size size) =>
      math.min(size.width, size.height) * 0.36;

  static List<Offset> satellites(Size size, double angle) {
    final c = centerOf(size);
    final r = orbitOf(size);
    return List.generate(3, (i) {
      final a = angle + i * 2 * math.pi / 3;
      return c + Offset(math.cos(a) * r, math.sin(a) * r * 0.82);
    });
  }

  void _showTip(String msg, Offset anchor) {
    _tipTimer?.cancel();
    setState(() {
      _tip = msg;
      _tipAnchor = anchor;
    });
    _tipTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _tip = null;
          _activeSat = null;
        });
      }
    });
  }

  void _onTapDown(TapDownDetails d) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final size = box.size;
    final local = d.localPosition;
    final c = centerOf(size);
    final sats = satellites(size, _ctrl.value * 2 * math.pi + _boost);
    for (var i = 0; i < sats.length; i++) {
      if ((local - sats[i]).distance < 24) {
        setState(() => _activeSat = i);
        _showTip(
          i == 0 ? 'Sesi aktif, terverifikasi' : 'Perangkat terhubung',
          sats[i],
        );
        return;
      }
    }
    if ((local - c).distance < 52) {
      setState(() => _boost += 0.6);
      _showTip('Ini kamu, rider', c);
    } else {
      setState(() {
        _tip = null;
        _activeSat = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: AspectRatio(
        aspectRatio: 14 / 10,
        child: FocusableActionDetector(
          focusNode: _focus,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                final box = context.findRenderObject() as RenderBox?;
                final at = box == null
                    ? Offset.zero
                    : Offset(box.size.width / 2, box.size.height / 2);
                setState(() => _boost += 0.6);
                _showTip('Ini kamu, rider', at);
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTapDown: reduce ? null : _onTapDown,
            child: RepaintBoundary(
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, _) => CustomPaint(
                      painter: _ProfilePainter(
                        t: _ctrl.value,
                        boost: _boost,
                        activeSat: _activeSat,
                        focused: _focused,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  if (_tip != null && _tipAnchor != null)
                    _TipChip(text: _tip!, anchor: _tipAnchor!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter({
    required this.t,
    required this.boost,
    required this.activeSat,
    required this.focused,
  });
  final double t;
  final double boost;
  final int? activeSat;
  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );
    canvas.drawRRect(card, Paint()..color = AppColors.surface);
    canvas.drawRRect(
      card,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.save();
    canvas.clipRRect(card);

    final c = _ProfileIllustrationState.centerOf(size);
    final orbit = _ProfileIllustrationState.orbitOf(size);
    final breathe = 1 + math.sin(t * 2 * math.pi * 4) * 0.015;

    final orbitRect = Rect.fromCenter(
      center: c,
      width: orbit * 2,
      height: orbit * 2 * 0.82,
    );
    canvas.drawOval(
      orbitRect,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final badgeR = math.min(size.width, size.height) * 0.22 * breathe;
    canvas.drawCircle(
      c,
      badgeR + 10,
      Paint()..color = AppColors.brandSoft,
    );
    canvas.drawCircle(c, badgeR, Paint()..color = AppColors.surface);
    canvas.drawCircle(
      c,
      badgeR,
      Paint()
        ..color = AppColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(
      c.translate(0, -badgeR * 0.32),
      badgeR * 0.30,
      Paint()..color = AppColors.ink,
    );
    final shoulders = Path()
      ..moveTo(c.dx - badgeR * 0.62, c.dy + badgeR * 0.72)
      ..quadraticBezierTo(
        c.dx - badgeR * 0.60, c.dy + badgeR * 0.05,
        c.dx, c.dy + badgeR * 0.02,
      )
      ..quadraticBezierTo(
        c.dx + badgeR * 0.60, c.dy + badgeR * 0.05,
        c.dx + badgeR * 0.62, c.dy + badgeR * 0.72,
      )
      ..close();
    canvas.drawPath(shoulders, Paint()..color = AppColors.brand);

    final starAt = c.translate(badgeR * 0.62, -badgeR * 0.62);
    canvas.drawCircle(starAt, 9, Paint()..color = AppColors.accent);
    canvas.drawCircle(
      starAt,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _drawStar(canvas, starAt, 4.5, Colors.white);

    final sats = _ProfileIllustrationState.satellites(
      size,
      t * 2 * math.pi + boost,
    );
    final satColors = [
      AppColors.brand,
      AppColors.accent,
      AppColors.ink,
    ];
    for (var i = 0; i < sats.length; i++) {
      final p = sats[i];
      if (activeSat == i) {
        canvas.drawCircle(
          p,
          12,
          Paint()
            ..color = satColors[i].withValues(alpha: 0.25),
        );
      }
      canvas.drawCircle(p, 6, Paint()..color = satColors[i]);
      canvas.drawCircle(
        p,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      canvas.drawCircle(p, 1.8, Paint()..color = Colors.white);
    }
    canvas.restore();

    if (focused) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          const Radius.circular(20),
        ),
        Paint()
          ..color = AppColors.brand
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outer = -math.pi / 2 + i * 2 * math.pi / 5;
      final inner = outer + math.pi / 5;
      final o = c + Offset(math.cos(outer) * r, math.sin(outer) * r);
      final n = c +
          Offset(math.cos(inner) * r * 0.45, math.sin(inner) * r * 0.45);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
      path.lineTo(n.dx, n.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter old) =>
      old.t != t ||
      old.boost != boost ||
      old.activeSat != activeSat ||
      old.focused != focused;
}

class _TipChip extends StatelessWidget {
  const _TipChip({required this.text, required this.anchor});
  final String text;
  final Offset anchor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: (anchor.dx - 70).clamp(8.0, 220.0),
      top: (anchor.dy - 52).clamp(8.0, 200.0),
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
