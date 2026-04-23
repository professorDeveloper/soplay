import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soplay/features/auth/domain/usecases/login_usecase.dart';
import 'package:soplay/features/auth/domain/usecases/register_usecase.dart';
import 'package:soplay/features/auth/presentation/bloc/auth_state.dart';

import 'auth_event.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;

  AuthBloc({required this.loginUseCase, required this.registerUseCase})
    : super(AuthInitial()) {
    on<AuthLoginRequested>(onLogin);
    on<AuthRegisterRequested>(onRegister);
  }

  Future<void> onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    var data = await loginUseCase(event.email, event.password);
    if (data.isSuccess) {
      emit(AuthLoaded(token: data.value!));
    } else {
      emit(
        AuthError(message: data.error?.toString() ?? 'Something went wrong'),
      );
    }
  }

  Future<void> onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    var data = await registerUseCase(
      event.email,
      event.password,
      event.username,
    );
    if (data.isSuccess) {
      emit(AuthLoaded(token: data.value!));
    } else {
      emit(
        AuthError(message: data.error?.toString() ?? 'Something went wrong'),
      );
    }
  }
}
