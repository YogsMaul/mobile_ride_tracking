import 'dart:async';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class PlaceSearchResult {
  final String displayName;
  final String shortName;
  final double lat;
  final double lng;

  const PlaceSearchResult({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lng,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    final rawName = json['display_name'] as String? ?? '';
    final parts = rawName.split(',');
    final short = parts.isNotEmpty ? parts.first.trim() : rawName;
    return PlaceSearchResult(
      displayName: rawName,
      shortName: short,
      lat: double.tryParse(json['lat']?.toString() ?? '') ?? 0.0,
      lng: double.tryParse(json['lon']?.toString() ?? '') ?? 0.0,
    );
  }
}

class RideRouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RideRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String get distanceFormatted {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters.round()} m';
  }

  String get durationFormatted {
    final mins = (durationSeconds / 60).round();
    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remMins = mins % 60;
      return '${hours}j ${remMins}m';
    }
    return '$mins mnt';
  }
}

class RouteService {
  final Dio _dio;

  RouteService([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  Options get _osmOptions => Options(
        headers: {
          'User-Agent': 'RideTrackingApp/1.0',
          'Accept-Language': 'id,en',
        },
      );

  /// Mencari tempat berdasarkan teks input pengguna via Nominatim OpenStreetMap (gratis).
  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': q,
          'format': 'json',
          'limit': 6,
          'addressdetails': 1,
        },
        options: _osmOptions,
      );

      final data = res.data;
      if (data is! List) return [];

      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => PlaceSearchResult.fromJson(json))
          .where((p) => p.lat != 0.0 && p.lng != 0.0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Mendapatkan nama jalan / tempat dari koordinat tap di peta via Nominatim Reverse Geocoding.
  Future<String> reverseGeocode(LatLng point) async {
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': point.latitude,
          'lon': point.longitude,
          'format': 'json',
          'addressdetails': 1,
        },
        options: _osmOptions,
      );

      final data = res.data;
      if (data is Map<String, dynamic>) {
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] ?? address['suburb'] ?? address['neighbourhood'];
          final city = address['city'] ?? address['town'] ?? address['county'] ?? address['state'];
          if (road != null && city != null) {
            return '$road, $city';
          }
          if (road != null) return '$road';
        }
        final raw = data['display_name'] as String?;
        if (raw != null && raw.isNotEmpty) {
          return raw.split(',').take(2).join(',').trim();
        }
      }
    } catch (_) {}

    return 'Titik Pilihan (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
  }

  /// Menghitung rute perjalanan jalan raya (ala Google Maps) via OSRM public routing.
  Future<RideRouteResult?> getRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    try {
      // OSRM format koordinat: {lng},{lat};{lng},{lat}
      final coords =
          '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}';
      final url =
          'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson';

      final res = await _dio.get(url);
      final data = res.data;
      if (data is! Map<String, dynamic> || data['code'] != 'Ok') {
        return null;
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final primary = routes[0] as Map<String, dynamic>;
      final geometry = primary['geometry'] as Map<String, dynamic>?;
      final rawCoords = geometry?['coordinates'] as List?;
      if (rawCoords == null || rawCoords.isEmpty) return null;

      final points = <LatLng>[];
      for (final c in rawCoords) {
        if (c is List && c.length >= 2) {
          final lng = (c[0] as num).toDouble();
          final lat = (c[1] as num).toDouble();
          points.add(LatLng(lat, lng));
        }
      }

      final dist = (primary['distance'] as num?)?.toDouble() ?? 0.0;
      final dur = (primary['duration'] as num?)?.toDouble() ?? 0.0;

      return RideRouteResult(
        points: points,
        distanceMeters: dist,
        durationSeconds: dur,
      );
    } catch (_) {
      return null;
    }
  }
}
