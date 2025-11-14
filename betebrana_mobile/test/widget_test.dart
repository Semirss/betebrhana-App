import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:betebrana_mobile/features/auth/data/auth_repository.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:betebrana_mobile/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('Login page renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider(
          create: (_) => AuthRepository(),
          child: BlocProvider(
            create: (context) => AuthBloc(context.read<AuthRepository>()),
            child: const LoginPage(),
          ),
        ),
      ),
    );

    expect(find.text('BeteBrana Login'), findsOneWidget);
  });
}
