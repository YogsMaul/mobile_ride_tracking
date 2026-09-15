import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/models/ride_detail_models.dart';
import '../../core/network/repository/ride_repository.dart';
import 'ride_history_item.dart';

class RideDetailState {
  final RideHistoryItem item;
  final List<RideTrailPoint> trail;
  final List<RideMember> members;

  const RideDetailState({
    required this.item,
    required this.trail,
    required this.members,
  });
}

final rideDetailProvider = FutureProvider.family<RideDetailState, RideHistoryItem>(
  (ref, item) async {
    final repo = ref.read(rideRepositoryProvider);
    final results = await Future.wait([
      repo.getRideTrail(item.id),
      repo.getRideMembers(item.id),
    ]);
    return RideDetailState(
      item: item,
      trail: results[0] as List<RideTrailPoint>,
      members: results[1] as List<RideMember>,
    );
  },
);
