import '../../domain/entities/auth_token.dart';
import 'user_model.dart';

class AuthModel extends AuthToken {
  AuthModel({
    required super.accessToken,
    required super.refreshToken,
    required super.user,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken:
          json['accessToken'] as String? ?? json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
