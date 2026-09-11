import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/models/ride_model.dart';

/// State ride aktif user.
class RideStateNotifier extends Notifier<RideModel?> {
  @override
  RideModel? build() => null;

  void setActive(RideModel ride) {
    state = ride;
  }

  void clear() {
    state = null;
  }
}

final rideStateProvider =
    NotifierProvider<RideStateNotifier, RideModel?>(RideStateNotifier.new);
