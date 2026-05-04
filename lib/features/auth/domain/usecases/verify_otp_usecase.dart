import '../../../../core/error/result.dart';
import '../entities/auth_token.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository _authRepository;

  VerifyOtpUseCase(this._authRepository);

  Future<Result<AuthToken>> call({
    required String email,
    required String code,
  }) {
    return _authRepository.verifyRegisterOtp(email: email, code: code);
  }
}
