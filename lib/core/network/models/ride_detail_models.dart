export 'ride_member_model.dart';

class RideTrailPoint {
  final double lat;
  final double lng;
  final DateTime timestamp;

  const RideTrailPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory RideTrailPoint.fromJson(Map<String, dynamic> json) =>
      RideTrailPoint(
        lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
        timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
            DateTime.now(),
      );
}
