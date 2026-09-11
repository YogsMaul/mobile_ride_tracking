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
}
