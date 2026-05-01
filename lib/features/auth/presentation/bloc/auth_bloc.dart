import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/core/error/result.dart';
import 'package:soplay/core/storage/hive_service.dart';
import 'package:soplay/features/auth/domain/entities/auth_token.dart';
import 'package:soplay/features/auth/domain/repositories/auth_repository.dart';
import 'package:soplay/features/auth/domain/usecases/login_usecase.dart';
import 'package:soplay/features/auth/domain/usecases/register_usecase.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_state.dart';

import 'auth_event.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final AuthRepository authRepository;
  final HiveService hiveService;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.authRepository,
    required this.hiveService,
  }) : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileRefreshRequested>(_onProfileRefresh);
    add(const AuthStarted());
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
    final result = await loginUseCase(event.email, event.password);
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
      event.email,
      event.password,
      event.username,
    );
    switch (result) {
      case Success(:final value):
        emit(AuthLoaded(token: value));
      case Failure(:final error):
        emit(AuthError(message: _friendlyError(error)));
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
    if (hiveService.getToken() == null) return;

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
        if (state is! AuthLoaded) emit(AuthInitial());
    }
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
