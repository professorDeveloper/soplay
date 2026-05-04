import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthLoginRequested extends AuthEvent {
  final String identifier;
  final String password;

  const AuthLoginRequested({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object?> get props => [identifier, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.username,
  });

  @override
  List<Object?> get props => [email, password, username];
}

class AuthOtpVerifyRequested extends AuthEvent {
  final String email;
  final String code;

  const AuthOtpVerifyRequested({required this.email, required this.code});

  @override
  List<Object?> get props => [email, code];
}

class AuthOtpResendRequested extends AuthEvent {
  final String email;

  const AuthOtpResendRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthOtpReset extends AuthEvent {
  const AuthOtpReset();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

class AuthProfileRefreshRequested extends AuthEvent {
  const AuthProfileRefreshRequested();
}
