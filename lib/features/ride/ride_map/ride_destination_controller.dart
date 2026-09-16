import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/service/route_service.dart';

/// State tujuan konvoi + rute OSRM + mode pilih-titik (pick mode).
/// Bangkitkan [notifyListeners] tiap ada perubahan biar peta rebuild.
class RideDestinationController extends ChangeNotifier {
  final RouteService _routes;

  RideDestinationController([RouteService? routes])
    : _routes = routes ?? RouteService();

  // --- tujuan aktif ---
  String? destName;
  LatLng? destPoint;
  RideRouteResult? routeResult;
  var isCalculatingRoute = false;

  // --- mode pilih titik ---
  var pickMode = false;
  LatLng? pickedPoint;
  String? pickedName;
  RideRouteResult? previewRoute;
  var previewUnavailable = false;

  Timer? _previewDebounce;

  /// Set dari server (initial fetch) atau echo WS — tanpa hit API ekstra
  /// di sini; caller yang panggil [refreshRoute] setelah posisi tersedia.
  void applyDestination(String name, LatLng point) {
    if (destName == name &&
        destPoint != null &&
        (destPoint!.latitude - point.latitude).abs() < 1e-9 &&
        (destPoint!.longitude - point.longitude).abs() < 1e-9) {
      return;
    }
    destName = name;
    destPoint = point;
    notifyListeners();
  }

  void applyPreview(String name, LatLng point, RideRouteResult preview) {
    destName = name;
    destPoint = point;
    routeResult = preview;
    notifyListeners();
  }

  void clear() {
    destName = null;
    destPoint = null;
    routeResult = null;
    notifyListeners();
  }

  /// Hitung ulang rute penuh (dipanggil setelah lokasi GPS berubah jauh
  /// atau setelah destination diterima).
  Future<void> refreshRoute(LatLng? start) async {
    final dest = destPoint;
    if (dest == null || start == null || isCalculatingRoute) return;
    isCalculatingRoute = true;
    notifyListeners();
    final route = await _routes.getRoute(start: start, destination: dest);
    routeResult = route;
    isCalculatingRoute = false;
    notifyListeners();
  }

  void startPick() {
    pickMode = true;
    pickedPoint = null;
    pickedName = null;
    previewRoute = null;
    previewUnavailable = false;
    notifyListeners();
  }

  void cancelPick() {
    _previewDebounce?.cancel();
    pickMode = false;
    pickedPoint = null;
    pickedName = null;
    previewRoute = null;
    previewUnavailable = false;
    notifyListeners();
  }

  /// Tap/long-press peta saat pick mode: reverse geocode + preview OSRM
  /// (debounce 400ms biar gak nembak API tiap geser jempol).
  Future<void> tapPoint(LatLng point, LatLng? start) async {
    pickedPoint = point;
    pickedName = 'Memuat nama lokasi…';
    previewRoute = null;
    previewUnavailable = false;
    notifyListeners();

    final name = await _routes.reverseGeocode(point);
    if (pickedPoint != point) return;
    pickedName = name;
    notifyListeners();
    _schedulePreview(point, start);
  }

  void _schedulePreview(LatLng point, LatLng? start) {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (start == null) {
        previewUnavailable = true;
        notifyListeners();
        return;
      }
      final route = await _routes.getRoute(start: start, destination: point);
      if (pickedPoint != point) return;
      previewRoute = route;
      previewUnavailable = route == null || route.points.isEmpty;
      notifyListeners();
    });
  }

  /// Terapkan titik terpilih jadi tujuan resmi, lalu keluar pick mode.
  void confirmPick() {
    final point = pickedPoint;
    if (point == null) return;
    _previewDebounce?.cancel();
    pickMode = false;
    pickedPoint = null;
    pickedName = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    super.dispose();
  }
}
