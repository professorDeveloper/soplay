import 'user_entity.dart';

class AuthToken {
  final String token;
  final UserEntity user;

  AuthToken({required this.token, required this.user});
}
