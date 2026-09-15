import 'package:latlong2/latlong.dart';

class RiderLocation {
  final String userId;
  final LatLng position;
  final double heading;
  final double speed;

  const RiderLocation({
    required this.userId,
    required this.position,
    required this.heading,
    required this.speed,
  });

  bool get isMoving => speed > 0.8;

  RiderLocation copyWith({
    LatLng? position,
    double? heading,
    double? speed,
  }) {
    return RiderLocation(
      userId: userId,
      position: position ?? this.position,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
    );
  }
}
