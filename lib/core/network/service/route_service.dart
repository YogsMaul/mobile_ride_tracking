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

  factory PlaceSearchResult.fromPhoton(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
    final coords = geometry['coordinates'] as List? ?? [];

    final name = (properties['name'] as String?)?.trim() ?? '';
    final street = (properties['street'] as String?)?.trim();
    final district = (properties['district'] as String?)?.trim();
    final city =
        ((properties['city'] ?? properties['town'] ?? properties['county'])
                as String?)
            ?.trim();
    final state = (properties['state'] as String?)?.trim();
    final country = (properties['country'] as String?)?.trim();

    final shortName = name.isNotEmpty ? name : (street ?? city ?? 'Lokasi');

    final parts = <String>[
      if (name.isNotEmpty) name,
      if (street != null && street.isNotEmpty && street != name) street,
      if (district != null && district.isNotEmpty) district,
      if (city != null && city.isNotEmpty && city != district) city,
      if (state != null && state.isNotEmpty) state,
      if (country != null && country.isNotEmpty) country,
    ];

    final displayName = parts.isNotEmpty ? parts.join(', ') : shortName;

    double lng = 0.0;
    double lat = 0.0;
    if (coords.length >= 2) {
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    }

    return PlaceSearchResult(
      displayName: displayName,
      shortName: shortName,
      lat: lat,
      lng: lng,
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
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  Options get _osmOptions => Options(
    headers: {'User-Agent': 'RideTrackingApp/1.0', 'Accept-Language': 'id,en'},
  );

  /// Mencari tempat berdasarkan input pengguna.
  /// Menggunakan Photon API (Komoot/Elasticsearch) dengan location bias terdekat,
  /// serta fallback ke Nominatim OSM jika offline/timeout.
  Future<List<PlaceSearchResult>> searchPlaces(
    String query, {
    LatLng? userLocation,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // 1. Coba Photon API (Elasticsearch, typo-tolerant & location bias)
    try {
      final params = <String, dynamic>{'q': q, 'limit': 7, 'lang': 'default'};
      if (userLocation != null) {
        params['lat'] = userLocation.latitude;
        params['lon'] = userLocation.longitude;
      }

      final res = await _dio.get(
        'https://photon.komoot.io/api/',
        queryParameters: params,
        options: _osmOptions,
      );

      final features = res.data?['features'] as List?;
      if (features != null && features.isNotEmpty) {
        final list = features
            .whereType<Map<String, dynamic>>()
            .map(PlaceSearchResult.fromPhoton)
            .where((p) => p.lat != 0.0 && p.lng != 0.0)
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      // Fallback ke Nominatim jika Photon request gagal
    }

    // 2. Fallback: Nominatim OpenStreetMap dengan prioritas Indonesia
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': q,
          'format': 'json',
          'limit': 6,
          'countrycodes': 'id',
          'addressdetails': 1,
        },
        options: _osmOptions,
      );

      final data = res.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(PlaceSearchResult.fromJson)
            .where((p) => p.lat != 0.0 && p.lng != 0.0)
            .toList();
      }
    } catch (_) {}

    return [];
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
          final road =
              address['road'] ?? address['suburb'] ?? address['neighbourhood'];
          final city =
              address['city'] ??
              address['town'] ??
              address['county'] ??
              address['state'];
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

  /// Menghitung rute perjalanan jalan raya terdekat via OSRM (alternatives=true & sort by shortest/fastest).
  Future<RideRouteResult?> getRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    try {
      // OSRM format koordinat: {lng},{lat};{lng},{lat}
      final coords =
          '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}';
      final url =
          'https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson&alternatives=true&steps=false';

      final res = await _dio.get(url);
      final data = res.data;
      if (data is! Map<String, dynamic> || data['code'] != 'Ok') {
        return null;
      }

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      // Pilih rute dengan jarak (distance) terpendek dari seluruh alternatif yang diberikan OSRM
      Map<String, dynamic>? bestRoute;
      double minDistance = double.infinity;

      for (final r in routes) {
        if (r is Map<String, dynamic>) {
          final dist = (r['distance'] as num?)?.toDouble() ?? double.infinity;
          if (dist < minDistance) {
            minDistance = dist;
            bestRoute = r;
          }
        }
      }

      bestRoute ??= routes[0] as Map<String, dynamic>;

      final geometry = bestRoute['geometry'] as Map<String, dynamic>?;
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

      final dist = (bestRoute['distance'] as num?)?.toDouble() ?? 0.0;
      final dur = (bestRoute['duration'] as num?)?.toDouble() ?? 0.0;

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
