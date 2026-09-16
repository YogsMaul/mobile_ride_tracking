import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/repository/ride_repository.dart';
import '../history/ride_history_item.dart';

class UserStats {
  final int totalRides;
  final String totalDistanceKm;
  final String totalDuration;

  const UserStats({
    required this.totalRides,
    required this.totalDistanceKm,
    required this.totalDuration,
  });

  static const empty = UserStats(
    totalRides: 0,
    totalDistanceKm: '—',
    totalDuration: '—',
  );
}

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  try {
    final repo = ref.watch(rideRepositoryProvider);
    // Ambil riwayat ride user (sample 100 terakhir)
    final rides = await repo.getMyRides(limit: 100);
    if (rides.isEmpty) return UserStats.empty;

    final totalRides = rides.length;

    // Hitung total durasi dari ride yang sudah selesai (ended_at > started_at)
    var totalMinutes = 0;
    for (final r in rides) {
      if (r.status == RideStatus.completed &&
          r.startedAt.year > 1970 &&
          r.endedAt.year > 1970 &&
          r.endedAt.isAfter(r.startedAt)) {
        totalMinutes += r.endedAt.difference(r.startedAt).inMinutes;
      }
    }

    String durStr;
    if (totalMinutes <= 0) {
      durStr = '—';
    } else {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      durStr = hours > 0 ? '${hours}j ${mins}m' : '${mins}m';
    }

    // ponytail: jarak per-ride belum diagregasi backend; upgrade via GET /me/stats
    return UserStats(
      totalRides: totalRides,
      totalDistanceKm: '—',
      totalDuration: durStr,
    );
  } catch (_) {
    return UserStats.empty;
  }
});
