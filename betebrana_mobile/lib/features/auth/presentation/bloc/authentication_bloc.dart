import 'dart:async';
import 'package:bloc/bloc.dart';

import '../../domain/entities/auth_user.dart';
import '../../data/auth_repository.dart';
import 'authentication_event.dart';
import 'authentication_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    final hasSession = await _authRepository.hasValidSession();
    if (!hasSession) {
      emit(const AuthUnauthenticated());
      return;
    }
    final user = await _authRepository.getCurrentUser();
    if (user == null) {
      // Clear any stale data and force re-login.
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } else {
      emit(AuthAuthenticated(user));
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final AuthUser user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
      // Don't emit AuthUnauthenticated here - keep showing the login page
      // The error will be displayed and user can try again
    }
  }

Future<void> _onRegisterRequested(
  AuthRegisterRequested event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthLoading());
  try {
    // Register (which now clears all sessions)
    await _authRepository.register(
      name: event.name,
      email: event.email,
      password: event.password,
    );
    
    // Emit registration success
    emit(const AuthRegistrationSuccess());
    

    await _authRepository.logout(); // Double-check logout
    emit(const AuthUnauthenticated());
    
  } catch (e) {
    emit(AuthFailure(e.toString()));
    emit(const AuthUnauthenticated());
  }
}

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}