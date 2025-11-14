import 'package:equatable/equatable.dart';

/// Base class for all authentication events.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when the app starts and we need to restore a session.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Fired when a user submits the login form.
class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Fired when a user submits the registration form.
class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

/// Fired when the user explicitly logs out or when a forced logout is triggered.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
