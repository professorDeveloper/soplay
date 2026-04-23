import '../../domain/entities/auth_token.dart';
import 'user_model.dart';

class AuthModel extends AuthToken {
  AuthModel({required super.token, required super.user});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
