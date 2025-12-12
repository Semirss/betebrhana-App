import 'package:betebrana_mobile/main_library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/authentication_bloc.dart';
import 'features/auth/presentation/bloc/authentication_event.dart';
import 'features/auth/presentation/bloc/authentication_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/library/presentation/pages/library_page.dart';
import 'features/library/presentation/pages/downloaded_books_page.dart';

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
          home: const _AppWrapper(), // Use a wrapper widget instead
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
  bool _justRegistered = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistrationSuccess) {
          // Set flag to prevent auto-login
          _justRegistered = true;
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please login.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to login
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
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
          
          if (_justRegistered) {
            return const MainLibraryPage();
          }
          
          // If authenticated, show library
          if (state is AuthAuthenticated) {
            return const MainLibraryPage();
          }
          
          // Otherwise show login
          return const LoginPage();
        },
      ),
    );
  }
  // Helper functions for navigation (add these outside the BeteBranaApp class)
void logoutAndNavigateToLogin(BuildContext context) {
  context.read<AuthBloc>().add(const AuthLogoutRequested());
  // Navigation is handled by the root BlocBuilder
}

void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
  Navigator.pushNamed(context, routeName, arguments: arguments);
}
}