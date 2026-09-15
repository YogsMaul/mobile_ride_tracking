import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../rider_location.dart';

List<Marker> buildRideMarkers({
  LatLng? currentPosition,
  double currentHeading = 0,
  bool currentIsMoving = false,
  required Map<String, RiderLocation> otherRiders,
  Map<String, String>? names,
  LatLng? destinationPoint,
  String? destinationName,
  bool destinationIsPreview = false,
}) {
  final markers = <Marker>[];

  if (destinationPoint != null) {
    markers.add(
      Marker(
        point: destinationPoint,
        width: 120,
        height: 80,
        alignment: Alignment.topCenter,
        child: DestinationPinMarker(
          label: destinationName ?? 'Tujuan',
          preview: destinationIsPreview,
        ),
      ),
    );
  }

  if (currentPosition != null) {
    markers.add(
      Marker(
        point: currentPosition,
        width: 72,
        height: 84,
        child: RiderAvatarMarker(
          label: 'Kamu',
          heading: currentHeading,
          isMoving: currentIsMoving,
          background: AppColors.brand,
        ),
      ),
    );
  }

  otherRiders.forEach((userId, rider) {
    final raw = (names?[userId] ?? '').trim();
    final label = raw.isEmpty
        ? (userId.length >= 4
            ? userId.substring(0, 4).toUpperCase()
            : userId.toUpperCase())
        : (raw.split(RegExp(r'\s+')).firstWhere(
            (p) => p.isNotEmpty,
            orElse: () => raw,
          ));
    markers.add(
      Marker(
        point: rider.position,
        width: 72,
        height: 84,
        child: RiderAvatarMarker(
          label: label.length > 10 ? '${label.substring(0, 10)}…' : label,
          heading: rider.heading,
          isMoving: rider.isMoving,
          background: AppColors.accent,
        ),
      ),
    );
  });

  return markers;
}

class DestinationPinMarker extends StatelessWidget {
  const DestinationPinMarker({
    super.key,
    required this.label,
    this.preview = false,
  });
  final String label;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final color = preview ? AppColors.brand : AppColors.warn;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 110),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Icon(
          preview ? Icons.place_rounded : Icons.flag_rounded,
          color: color,
          size: 32,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
        ),
      ],
    );
  }
}

class RiderAvatarMarker extends StatelessWidget {
  const RiderAvatarMarker({
    super.key,
    required this.label,
    required this.heading,
    required this.isMoving,
    required this.background,
  });

  final String label;
  final double heading;
  final bool isMoving;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 3),
        _Bounce(
          bounce: isMoving,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isMoving) _PulseRing(color: background),
                Transform.rotate(
                  angle: heading * math.pi / 180,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 1),
                      width: 0,
                      height: 0,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.transparent, width: 6),
                          right: BorderSide(color: Colors.transparent, width: 6),
                          bottom: BorderSide(color: Colors.white, width: 8),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: background.withValues(alpha: 0.45),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.two_wheeler,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.color});
  final Color color;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();
  late final Animation<double> _scale = Tween(begin: 0.7, end: 1.35).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeOut),
  );
  late final Animation<double> _opacity = Tween(begin: 0.55, end: 0.0).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bounce extends StatefulWidget {
  const _Bounce({required this.bounce, required this.child});
  final bool bounce;
  final Widget child;

  @override
  State<_Bounce> createState() => _BounceState();
}

class _BounceState extends State<_Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _dy = Tween(begin: 0.0, end: -3.0).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    if (widget.bounce) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Bounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bounce && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.bounce && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.bounce) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => Transform.translate(
        offset: Offset(0, _dy.value),
        child: widget.child,
      ),
    );
  }
}
