import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.email,
    super.username,
    super.displayName,
    super.photoURL,
    super.authProvider,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      authProvider: json['authProvider'] as String? ?? 'local',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'email': email,
    'username': username,
    'displayName': displayName,
    'photoURL': photoURL,
    'authProvider': authProvider,
    'createdAt': createdAt?.toIso8601String(),
  };
}
