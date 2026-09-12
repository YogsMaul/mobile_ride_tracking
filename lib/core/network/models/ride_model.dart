class RideModel {
  final String id;
  final String? name;
  final String? inviteCode;
  final String? status;

  const RideModel({
    this.id = '',
    this.name,
    this.inviteCode,
    this.status,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) => RideModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String?,
        inviteCode: json['invite_code'] as String?,
        status: json['status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (name != null) 'name': name,
        if (inviteCode != null) 'invite_code': inviteCode,
        if (status != null) 'status': status,
      };

  RideModel copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? status,
  }) =>
      RideModel(
        id: id ?? this.id,
        name: name ?? this.name,
        inviteCode: inviteCode ?? this.inviteCode,
        status: status ?? this.status,
      );

  String get displayCode {
    final raw = (inviteCode ?? id).replaceAll('-', '');
    return raw.length >= 8
        ? raw.substring(0, 8).toUpperCase()
        : raw.toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          inviteCode == other.inviteCode &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, name, inviteCode, status);
}
