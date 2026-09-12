/// Filter enum riwayat — mapping label UI (spec 23).
enum RideHistoryFilter {
  all,
  host,
  joined,
  completed;

  String get label => switch (this) {
        RideHistoryFilter.all => 'Semua',
        RideHistoryFilter.host => 'Host',
        RideHistoryFilter.joined => 'Gabung',
        RideHistoryFilter.completed => 'Selesai',
      };
}
