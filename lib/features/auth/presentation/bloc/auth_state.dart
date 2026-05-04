import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_token.dart';

class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthLoaded extends AuthState {
  final AuthToken token;

  AuthLoaded({required this.token});

  @override
  List<Object?> get props => [
    token.accessToken,
    token.refreshToken,
    token.user,
  ];
}

/// Register OTP yuborildi — verify page'ga o'tish kerak.
class AuthOtpPending extends AuthState {
  final String email;
  final DateTime cooldownUntil;
  final bool justResent;
  final bool verifying;
  final bool resending;
  final String? error;

  AuthOtpPending({
    required this.email,
    required this.cooldownUntil,
    this.justResent = false,
    this.verifying = false,
    this.resending = false,
    this.error,
  });

  AuthOtpPending copyWith({
    DateTime? cooldownUntil,
    bool? justResent,
    bool? verifying,
    bool? resending,
    String? error,
    bool clearError = false,
  }) {
    return AuthOtpPending(
      email: email,
      cooldownUntil: cooldownUntil ?? this.cooldownUntil,
      justResent: justResent ?? this.justResent,
      verifying: verifying ?? this.verifying,
      resending: resending ?? this.resending,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    email,
    cooldownUntil,
    justResent,
    verifying,
    resending,
    error,
  ];
}
