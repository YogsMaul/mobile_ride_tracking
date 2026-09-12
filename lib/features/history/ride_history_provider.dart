import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/repository/ride_repository.dart';
import 'ride_history_item.dart';

/// FutureProvider yang fetch riwayat ride dari GET /rides/me.
/// Cache otomatis oleh Riverpod sampai di-invalidate (mis. setelah
/// selesai/batal ride baru, atau pull-to-refresh di history tab).
///
/// Return List kosong kalau error — history screen render empty state.
final rideHistoryProvider = FutureProvider<List<RideHistoryItem>>((ref) async {
  final repo = ref.read(rideRepositoryProvider);
  try {
    return await repo.getMyRides();
  } catch (_) {
    return [];
  }
});
