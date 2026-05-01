import 'package:soplay/core/error/result.dart';

import '../entities/auth_token.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Result<AuthToken>> login(String email, String password);

  Future<Result<AuthToken>> register(
    String email,
    String password,
    String username,
  );

  Future<Result<UserEntity>> getProfile();

  Future<void> logout();
}
