import 'user_entity.dart';

class AuthToken {
  final String accessToken;
  final String refreshToken;
  final UserEntity user;

  AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  String get token => accessToken;
}
