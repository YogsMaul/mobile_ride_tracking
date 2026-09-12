import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Toast custom yang muncul dari ATAS (bawah status bar), bukan SnackBar
/// bawaan yang nempel di bawah (bentrok navbar floating + keyboard).
///
/// Overlay-based: satu baris pemanggilan, auto-dismiss, antri tunggal
/// (toast baru menggantikan yang masih tampil).
///
/// ```dart
/// AppToast.success(context, 'Ride dibuat!');
/// AppToast.error(context, 'Gagal join ride.');
/// AppToast.info(context, 'GPS belum aktif.');
/// ```
enum _ToastKind { success, error, info }

class AppToast {
  AppToast._();

  static OverlayEntry? _entry;

  static void success(BuildContext context, String message, [int ms = 2500]) {
    _show(context, message, _ToastKind.success, ms);
  }

  static void error(BuildContext context, String message, [int ms = 3000]) {
    _show(context, message, _ToastKind.error, ms);
  }

  static void info(BuildContext context, String message, [int ms = 2500]) {
    _show(context, message, _ToastKind.info, ms);
  }

  static void _show(
    BuildContext context,
    String message,
    _ToastKind kind,
    int ms,
  ) {
    _entry?.remove();
    _entry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        kind: kind,
        onDismissed: () {
          entry.remove();
          if (_entry == entry) _entry = null;
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);

    Future.delayed(Duration(milliseconds: ms), () {
      if (_entry == entry) {
        entry.remove();
        _entry = null;
      }
    });
  }

  /// Tutup toast yang sedang tampil (misal sebelum navigasi).
  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.message,
    required this.kind,
    required this.onDismissed,
  });

  final String message;
  final _ToastKind kind;
  final VoidCallback onDismissed;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, icon) = switch (widget.kind) {
      _ToastKind.success => (AppColors.brand, Icons.check_circle),
      _ToastKind.error => (AppColors.warn, Icons.error_outline),
      _ToastKind.info => (AppColors.ink, Icons.info_outline),
    };

    final top = MediaQuery.paddingOf(context).top + 12;

    return Positioned(
      top: top,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: widget.onDismissed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
