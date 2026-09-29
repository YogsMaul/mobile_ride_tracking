import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'rider_location.dart';

/// Interpolasi posisi rider lain biar marker jalan mulus (gak patah).
/// Timer 100ms: posisi tampil didekatkan 30% ke posisi target tiap tick.
class RideSmoothingController extends ChangeNotifier {
  Timer? _timer;
  final Map<String, RiderLocation> _targets = {};
  var _smooth = <String, RiderLocation>{};

  Map<String, RiderLocation> get smooth =>
      _smooth.isNotEmpty ? _smooth : _targets;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
  }

  /// Terima lokasi mentah dari WS. [_targets] = ground truth.
  void update(String userId, RiderLocation target) {
    _targets[userId] = target;
    _smooth.putIfAbsent(userId, () => target);
  }

  void remove(String userId) {
    _targets.remove(userId);
    _smooth.remove(userId);
    notifyListeners();
  }

  void clearAll() {
    _targets.clear();
    _smooth.clear();
    notifyListeners();
  }

  void _tick() {
    if (_targets.isEmpty) return;
    var changed = false;
    final next = <String, RiderLocation>{};
    _targets.forEach((id, target) {
      final cur = _smooth[id];
      if (cur == null) {
        next[id] = target;
        changed = true;
        return;
      }
      // Interpolasi 60fps (33ms) dengan faktor 0.15 agar perpindahan halus
      final lat =
          cur.position.latitude +
          (target.position.latitude - cur.position.latitude) * 0.15;
      final lng =
          cur.position.longitude +
          (target.position.longitude - cur.position.longitude) * 0.15;
      final dLat = (target.position.latitude - lat).abs();
      final dLng = (target.position.longitude - lng).abs();

      // Interpolasi angular heading
      var hDiff = (target.heading - cur.heading + 180) % 360 - 180;
      final smoothHeading = (cur.heading + hDiff * 0.15 + 360) % 360;

      if (dLat < 1e-7 && dLng < 1e-7) {
        next[id] = target;
      } else {
        next[id] = cur.copyWith(
          position: LatLng(lat, lng),
          heading: smoothHeading,
          speed: target.speed,
        );
        changed = true;
      }
      if ((cur.heading - target.heading).abs() > 0.2 ||
          (cur.speed - target.speed).abs() > 0.1) {
        changed = true;
      }
    });
    if (_smooth.length != next.length) changed = true;
    if (changed) {
      _smooth = next;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
