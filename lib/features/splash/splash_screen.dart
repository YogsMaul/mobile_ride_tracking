import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_environment.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/service/device_registration_service.dart';
import '../../core/utils/security_helper.dart';
import '../../core/widgets/security_dialog.dart';
import '../auth/auth_state.dart';

/// Halaman splash Flutter — berlatar putih bersih dengan siluet pegunungan minimalis di dasar layar.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeIn,
  );

  @override
  void initState() {
    super.initState();
    _anim.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final isEmu = await SecurityHelper.isEmulator();
    if (isEmu && mounted) {
      final isProd = ApiConstants.environmentConfig.environment == AppEnvironment.prod;
      if (isProd) {
        await SecurityDialog.show(
          context: context,
          message:
              'Aplikasi terdeteksi berjalan pada perangkat emulator/virtual. Pada mode produksi, aplikasi hanya dapat dijalankan pada perangkat fisik.',
        );
        return;
      }
    }

    final auth = ref.read(authStateProvider);
    final deviceService = DeviceRegistrationService();

    try {
      await deviceService.registerDeviceIfNeeded();
    } catch (e) {
      debugPrint('[SplashScreen] Device registration warning: $e');
    }

    await Future.wait([
      auth.bootstrap(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Siluet pemandangan gunung minimalis & halus di bagian bawah
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 180,
            child: CustomPaint(
              painter: _MountainSilhouettePainter(),
            ),
          ),

          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  ScaleTransition(
                    scale: _scale,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF217E56).withValues(alpha: 0.12),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/logo_ride_tracking.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        const Text(
                          'Ride Tracking',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Konvoi real-time lebih aman & terorganisir',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF217E56),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'v1.0.0',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter untuk siluet pegunungan lembut bertingkat di dasar layar
class _MountainSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Lapisan gunung belakang (sangat lembut / tipis)
    final backMountainPaint = Paint()
      ..color = const Color(0xFF217E56).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final backPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.45)
      ..cubicTo(w * 0.2, h * 0.15, w * 0.35, h * 0.6, w * 0.55, h * 0.25)
      ..cubicTo(w * 0.75, h * -0.05, w * 0.88, h * 0.4, w, h * 0.3)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(backPath, backMountainPaint);

    // Lapisan bukit tengah (sedang lembut)
    final midMountainPaint = Paint()
      ..color = const Color(0xFF217E56).withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;

    final midPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.65)
      ..cubicTo(w * 0.18, h * 0.4, w * 0.4, h * 0.75, w * 0.68, h * 0.45)
      ..cubicTo(w * 0.85, h * 0.25, w * 0.95, h * 0.55, w, h * 0.5)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(midPath, midMountainPaint);

    // Lapisan bukit depan & jalanan lembut
    final frontMountainPaint = Paint()
      ..color = const Color(0xFF217E56).withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    final frontPath = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.8)
      ..cubicTo(w * 0.25, h * 0.65, w * 0.45, h * 0.85, w * 0.75, h * 0.68)
      ..cubicTo(w * 0.88, h * 0.6, w * 0.95, h * 0.75, w, h * 0.7)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(frontPath, frontMountainPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
