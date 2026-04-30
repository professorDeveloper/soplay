class UserEntity {
  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? photoURL;
  final String authProvider;
  final DateTime? createdAt;

  UserEntity({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.photoURL,
    this.authProvider = 'local',
    this.createdAt,
  });

  String get displayIdentifier => username ?? displayName ?? email.split('@').first;
}
