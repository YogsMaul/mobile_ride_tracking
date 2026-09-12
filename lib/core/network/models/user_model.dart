class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? createdAt;

  const UserModel({
    this.id = '',
    this.email = '',
    this.name = '',
    this.role = 'user',
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? 'user',
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        if (createdAt != null) 'created_at': createdAt,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          role == other.role &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, email, name, role, createdAt);
}

class AuthResponseModel {
  final String accessToken;
  final String? refreshToken;
  final UserModel? user;

  const AuthResponseModel({
    this.accessToken = '',
    this.refreshToken,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      AuthResponseModel(
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String?,
        user: json['user'] is Map<String, dynamic>
            ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
        if (user != null) 'user': user!.toJson(),
      };
}
