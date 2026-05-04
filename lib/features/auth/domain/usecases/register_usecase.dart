import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  Future<Result<void>> call({
    required String email,
    required String username,
    required String password,
  }) {
    return _authRepository.requestRegisterOtp(
      email: email,
      username: username,
      password: password,
    );
  }
}
