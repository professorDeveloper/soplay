import '../../../../core/error/result.dart';
import '../repositories/auth_repository.dart';

class ResendOtpUseCase {
  final AuthRepository _authRepository;

  ResendOtpUseCase(this._authRepository);

  Future<Result<void>> call(String email) {
    return _authRepository.resendRegisterOtp(email);
  }
}
