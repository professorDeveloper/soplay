import '../../../../core/error/result.dart';
import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  Future<Result<AuthToken>> call(
    String email,
    String password,
    String username,
  ) async {
    return await _authRepository.register(email, password, username);
  }
}
