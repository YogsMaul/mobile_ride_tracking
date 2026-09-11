import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/theme/app_theme.dart';
import '../rider_location.dart';

List<Marker> buildRideMarkers({
  LatLng? currentPosition,
  required Map<String, RiderLocation> otherRiders,
}) {
  final markers = <Marker>[];

  if (currentPosition != null) {
    markers.add(
      Marker(
        point: currentPosition,
        width: 40,
        height: 40,
        child: const MyMarker(),
      ),
    );
  }

  otherRiders.forEach((userId, rider) {
    markers.add(
      Marker(
        point: rider.position,
        width: 56,
        height: 60,
        child: RiderMarker(userId: userId),
      ),
    );
  });

  return markers;
}

class MyMarker extends StatelessWidget {
  const MyMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.navigation, color: Colors.white, size: 18),
    );
  }
}

class RiderMarker extends StatelessWidget {
  const RiderMarker({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            userId.length >= 4
                ? userId.substring(0, 4).toUpperCase()
                : userId.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.two_wheeler, color: Colors.white, size: 14),
        ),
      ],
    );
  }
}
