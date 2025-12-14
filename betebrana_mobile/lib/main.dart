import 'package:betebrana_mobile/main_library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

    return RepositoryProvider.value(
      value: authRepository,
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository)..add(const AuthStarted()),
        child: MaterialApp(
          title: 'BeteBrana Library',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          home: const _AppWrapper(),
        ),
      ),
    );
  }
}

class _AppWrapper extends StatefulWidget {
  const _AppWrapper();

  @override
  State<_AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<_AppWrapper> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistrationSuccess) {
          // Instead of pushing and destroying the wrapper, we just pop back to root
          // effectively closing the RegisterPage if it's open.
          Navigator.of(context).popUntil((route) => route.isFirst);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // If we somehow logged in while a different page was pushed on top,
        // clear the stack so MainLibraryPage is visible.
        if (state is AuthAuthenticated) {
           Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Show loading while checking auth
          if (state is AuthLoading || state is AuthInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If authenticated, show library
          if (state is AuthAuthenticated) {
            return const MainLibraryPage();
          }

          // Default state (Unauthenticated, RegistrationSuccess, Error) -> Show Login
          return const LoginPage();
        },
      ),
    );
  }
}

// Helper functions for navigation
void logoutAndNavigateToLogin(BuildContext context) {
  context.read<AuthBloc>().add(const AuthLogoutRequested());
  // The BlocBuilder in _AppWrapper will handle showing the LoginPage
}

void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
  Navigator.pushNamed(context, routeName, arguments: arguments);
}