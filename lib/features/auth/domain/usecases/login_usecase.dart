import '../../../../core/error/result.dart';
import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _authRepository;
  LoginUseCase(this._authRepository);
  Future<Result<AuthToken>> call(String email, String password) async {
    return await _authRepository.login(email, password);
  }
}