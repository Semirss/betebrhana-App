import 'package:betebrana_mobile/main_library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/services/language_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/authentication_bloc.dart';
import 'features/auth/presentation/bloc/authentication_event.dart';
import 'features/auth/presentation/bloc/authentication_state.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BeteBranaApp());
}

/// Root widget for the BeteBrana mobile app.
class BeteBranaApp extends StatelessWidget {
  const BeteBranaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageBloc>(create: (_) => LanguageBloc()),
        RepositoryProvider.value(value: authRepository),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository)..add(const AuthStarted()),
        ),
      ],
      child: const _ThemeWrapper(),
    );
  }
}

/// Listens to ThemeBloc (created inside MainLibraryPage) at the root level.
/// For the login screen, we always use light theme.
class _ThemeWrapper extends StatelessWidget {
  const _ThemeWrapper();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeteBrana Library',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: const _AppWrapper(),
    );
  }
}

class _AppWrapper extends StatelessWidget {
  const _AppWrapper();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistrationSuccess) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state is AuthAuthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading || state is AuthInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is AuthAuthenticated) {
            return const MainLibraryPage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}

// Helper functions for navigation
void logoutAndNavigateToLogin(BuildContext context) {
  context.read<AuthBloc>().add(const AuthLogoutRequested());
}