class RideMember {
  final String userId;
  final String name;
  final String? avatarUrl;
  final String role; // "host" atau "member"
  final DateTime joinedAt;

  const RideMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
  });

  bool get isHost => role == 'host';

  factory RideMember.fromJson(Map<String, dynamic> json) {
    DateTime parseTime(dynamic raw) {
      if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return RideMember(
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Pengendara',
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      joinedAt: parseTime(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'role': role,
        'joined_at': joinedAt.toIso8601String(),
      };
}
