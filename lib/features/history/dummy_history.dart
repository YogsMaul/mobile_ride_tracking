import 'ride_history_item.dart';

/// Dummy data riwayat 5 item sesuai spec 21.
/// Dipakai sebagai placeholder sampai backend siap dengan endpoint list-my-rides.
final List<RideHistoryItem> dummyHistoryItems = [
  RideHistoryItem(
    id: '1',
    title: 'Sunset Ride Palembang',
    date: DateTime(2026, 9, 8),
    participantCount: 8,
    role: RideRole.host,
    startedAt: DateTime(2026, 9, 8, 17, 24),
    endedAt: DateTime(2026, 9, 8, 19, 2),
    status: RideStatus.completed,
  ),
  RideHistoryItem(
    id: '2',
    title: 'Morning Ride Jakabaring',
    date: DateTime(2026, 9, 7),
    participantCount: 5,
    role: RideRole.joined,
    startedAt: DateTime(2026, 9, 7, 6, 12),
    endedAt: DateTime(2026, 9, 7, 8, 5),
    status: RideStatus.completed,
  ),
  RideHistoryItem(
    id: '3',
    title: 'Night Ride City Tour',
    date: DateTime(2026, 9, 6),
    participantCount: 12,
    role: RideRole.host,
    startedAt: DateTime(2026, 9, 6, 20, 15),
    endedAt: DateTime(2026, 9, 6, 22, 10),
    status: RideStatus.completed,
  ),
  RideHistoryItem(
    id: '4',
    title: 'Coffee Ride KM 12',
    date: DateTime(2026, 9, 5),
    participantCount: 4,
    role: RideRole.joined,
    startedAt: DateTime(2026, 9, 5, 7, 30),
    endedAt: DateTime(2026, 9, 5, 9, 10),
    status: RideStatus.completed,
  ),
  RideHistoryItem(
    id: '5',
    title: 'Bukit Siguntang Loop',
    date: DateTime(2026, 9, 4),
    participantCount: 6,
    role: RideRole.host,
    startedAt: DateTime(2026, 9, 4, 16, 40),
    endedAt: DateTime(2026, 9, 4, 18, 25),
    status: RideStatus.cancelled,
  ),
];
