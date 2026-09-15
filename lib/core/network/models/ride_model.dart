class RideModel {
  final String id;
  final String? ownerId;
  final String? name;
  final String? inviteCode;
  final String? status;
  final String? destName;
  final double? destLat;
  final double? destLng;

  const RideModel({
    this.id = '',
    this.ownerId,
    this.name,
    this.inviteCode,
    this.status,
    this.destName,
    this.destLat,
    this.destLng,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) => RideModel(
        id: json['id'] as String? ?? '',
        ownerId: json['owner_id'] as String?,
        name: json['name'] as String?,
        inviteCode: json['invite_code'] as String?,
        status: json['status'] as String?,
        destName: json['dest_name'] as String?,
        destLat: (json['dest_lat'] as num?)?.toDouble(),
        destLng: (json['dest_lng'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (ownerId != null) 'owner_id': ownerId,
        if (name != null) 'name': name,
        if (inviteCode != null) 'invite_code': inviteCode,
        if (status != null) 'status': status,
        if (destName != null) 'dest_name': destName,
        if (destLat != null) 'dest_lat': destLat,
        if (destLng != null) 'dest_lng': destLng,
      };

  RideModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? inviteCode,
    String? status,
    String? destName,
    double? destLat,
    double? destLng,
  }) =>
      RideModel(
        id: id ?? this.id,
        ownerId: ownerId ?? this.ownerId,
        name: name ?? this.name,
        inviteCode: inviteCode ?? this.inviteCode,
        status: status ?? this.status,
        destName: destName ?? this.destName,
        destLat: destLat ?? this.destLat,
        destLng: destLng ?? this.destLng,
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
          ownerId == other.ownerId &&
          name == other.name &&
          inviteCode == other.inviteCode &&
          status == other.status &&
          destName == other.destName &&
          destLat == other.destLat &&
          destLng == other.destLng;

  @override
  int get hashCode =>
      Object.hash(id, ownerId, name, inviteCode, status, destName, destLat, destLng);
}
