class RideModel {
  final String id;
  final String? name;
  final String? inviteCode;
  final String? status;

  const RideModel({
    required this.id,
    this.name,
    this.inviteCode,
    this.status,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      inviteCode: json['invite_code'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'invite_code': inviteCode,
        'status': status,
      };

  /// Kode tampilan 8 char dari invite code / ride id.
  String get displayCode {
    final raw = (inviteCode ?? id).replaceAll('-', '');
    return raw.length >= 8
        ? raw.substring(0, 8).toUpperCase()
        : raw.toUpperCase();
  }
}
