import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

final class RegisterSubmitted extends AuthEvent {
  final String username;
  final String password;

  const RegisterSubmitted({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
