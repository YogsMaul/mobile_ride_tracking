class RideHistoryItem {
  final String id;
  final String title;
  final DateTime date;
  final int participantCount;
  final RideRole role;
  final DateTime startedAt;
  final DateTime endedAt;
  final RideStatus status;

  const RideHistoryItem({
    required this.id,
    required this.title,
    required this.date,
    required this.participantCount,
    required this.role,
    required this.startedAt,
    required this.endedAt,
    required this.status,
  });

  factory RideHistoryItem.fromJson(Map<String, dynamic> json) =>
      RideHistoryItem(
        id: json['id'] as String? ?? '',
        title: (json['title'] as String?) ??
            (json['name'] as String?) ??
            'Ride tanpa nama',
        date: _parseDate(json['date'] ?? json['created_at']),
        participantCount: json['participant_count'] as int? ?? 0,
        role: _parseRole(json['role']),
        startedAt: _parseDate(json['started_at']),
        endedAt: _parseDate(json['ended_at']),
        status: _parseStatus(json['status']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'participant_count': participantCount,
        'role': role.name,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt.toIso8601String(),
        'status': status.name,
      };

  RideHistoryItem copyWith({
    String? id,
    String? title,
    DateTime? date,
    int? participantCount,
    RideRole? role,
    DateTime? startedAt,
    DateTime? endedAt,
    RideStatus? status,
  }) =>
      RideHistoryItem(
        id: id ?? this.id,
        title: title ?? this.title,
        date: date ?? this.date,
        participantCount: participantCount ?? this.participantCount,
        role: role ?? this.role,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        status: status ?? this.status,
      );

  String get timeRange {
    String fmt(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final dur = endedAt.difference(startedAt);
    return '${fmt(startedAt)} – ${fmt(endedAt)} · ${dur.inHours}j ${dur.inMinutes % 60}m';
  }

  String get roleLabel => role == RideRole.host ? 'Host' : 'Gabung';

  String get metadata => '$participantCount peserta · $roleLabel';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideHistoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          date == other.date &&
          participantCount == other.participantCount &&
          role == other.role &&
          startedAt == other.startedAt &&
          endedAt == other.endedAt &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        date,
        participantCount,
        role,
        startedAt,
        endedAt,
        status,
      );
}

enum RideRole { host, joined }

enum RideStatus { completed, cancelled }

DateTime _parseDate(Object? value) {
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime(1970);
  }
  return DateTime(1970);
}

RideRole _parseRole(Object? value) {
  for (final r in RideRole.values) {
    if (r.name == value) return r;
  }
  return RideRole.joined;
}

RideStatus _parseStatus(Object? value) {
  for (final s in RideStatus.values) {
    if (s.name == value) return s;
  }
  return RideStatus.completed;
}
