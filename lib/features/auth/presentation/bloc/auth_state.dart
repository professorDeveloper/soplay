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
}

class AuthLoaded extends AuthState {
  final AuthToken token;

  AuthLoaded({required this.token});
}
