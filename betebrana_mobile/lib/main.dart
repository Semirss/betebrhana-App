import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/authentication_bloc.dart';
import 'features/auth/presentation/bloc/authentication_event.dart';
import 'features/auth/presentation/bloc/authentication_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/library/presentation/pages/library_page.dart';

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
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading || state is AuthInitial) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is AuthAuthenticated) {
                return const LibraryPage();
              }
              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }
}
