import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/auth/domain/entities/auth_token.dart';
import 'package:soplay/features/auth/domain/repositories/auth_repository.dart';
import 'package:soplay/features/auth/domain/usecases/login_usecase.dart';
import 'package:soplay/features/auth/domain/usecases/register_usecase.dart';
import 'package:soplay/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:soplay/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_state.dart';

import 'auth_event.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final ResendOtpUseCase resendOtpUseCase;
  final AuthRepository authRepository;
  final HiveService hiveService;

  static const Duration _resendCooldown = Duration(seconds: 60);

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.verifyOtpUseCase,
    required this.resendOtpUseCase,
    required this.authRepository,
    required this.hiveService,
  }) : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthOtpVerifyRequested>(_onVerifyOtp);
    on<AuthOtpResendRequested>(_onResendOtp);
    on<AuthOtpReset>((_, emit) => emit(AuthInitial()));
    on<AuthLogoutRequested>(_onLogout);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthProfileRefreshRequested>(_onProfileRefresh);
    add(const AuthStarted());
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await hiveService.clearAuth();
    emit(AuthInitial());
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final accessToken = hiveService.getToken();
    final user = hiveService.getUser();
    if (accessToken == null || accessToken.isEmpty || user == null) {
      emit(AuthInitial());
      return;
    }

    emit(
      AuthLoaded(
        token: AuthToken(
          accessToken: accessToken,
          refreshToken: hiveService.getRefreshToken() ?? '',
          user: user,
        ),
      ),
    );

    add(const AuthProfileRefreshRequested());
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(event.identifier, event.password);
    switch (result) {
      case Success(:final value):
        emit(AuthLoaded(token: value));
      case Failure(:final error):
        emit(AuthError(message: _friendlyError(error)));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await registerUseCase(
      email: event.email,
      username: event.username,
      password: event.password,
    );
    switch (result) {
      case Success():
        emit(
          AuthOtpPending(
            email: event.email,
            cooldownUntil: DateTime.now().add(_resendCooldown),
          ),
        );
      case Failure(:final error):
        emit(AuthError(message: _friendlyError(error)));
    }
  }

  Future<void> _onVerifyOtp(
    AuthOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is AuthOtpPending) {
      emit(current.copyWith(verifying: true, clearError: true));
    }
    final result = await verifyOtpUseCase(email: event.email, code: event.code);
    switch (result) {
      case Success(:final value):
        emit(AuthLoaded(token: value));
      case Failure(:final error):
        final msg = _friendlyError(error);
        if (current is AuthOtpPending) {
          emit(current.copyWith(verifying: false, error: msg));
        } else {
          emit(AuthError(message: msg));
        }
    }
  }

  Future<void> _onResendOtp(
    AuthOtpResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is AuthOtpPending) {
      if (DateTime.now().isBefore(current.cooldownUntil)) return;
      emit(current.copyWith(resending: true, clearError: true));
    }
    final result = await resendOtpUseCase(event.email);
    switch (result) {
      case Success():
        if (current is AuthOtpPending) {
          emit(
            current.copyWith(
              resending: false,
              justResent: true,
              cooldownUntil: DateTime.now().add(_resendCooldown),
            ),
          );
        } else {
          emit(
            AuthOtpPending(
              email: event.email,
              cooldownUntil: DateTime.now().add(_resendCooldown),
              justResent: true,
            ),
          );
        }
      case Failure(:final error):
        final msg = _friendlyError(error);
        if (current is AuthOtpPending) {
          emit(current.copyWith(resending: false, error: msg));
        } else {
          emit(AuthError(message: msg));
        }
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(AuthInitial());
  }

  Future<void> _onProfileRefresh(
    AuthProfileRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    final accessToken = hiveService.getToken();
    if (accessToken == null || accessToken.isEmpty) {
      if (current is AuthLoaded) emit(AuthInitial());
      return;
    }

    final result = await authRepository.getProfile();
    switch (result) {
      case Success(:final value):
        emit(
          AuthLoaded(
            token: AuthToken(
              accessToken: hiveService.getToken() ?? '',
              refreshToken: hiveService.getRefreshToken() ?? '',
              user: value,
            ),
          ),
        );
      case Failure():
        final stillAuthenticated = hiveService.getToken()?.isNotEmpty == true;
        if (!stillAuthenticated) {
          emit(AuthInitial());
          return;
        }
        if (current is AuthLoaded) return;
        final cachedUser = hiveService.getUser();
        if (cachedUser != null) {
          emit(
            AuthLoaded(
              token: AuthToken(
                accessToken: hiveService.getToken() ?? '',
                refreshToken: hiveService.getRefreshToken() ?? '',
                user: cachedUser,
              ),
            ),
          );
        }
    }
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
