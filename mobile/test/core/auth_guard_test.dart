import 'package:cramly/core/auth/auth_providers.dart';
import 'package:cramly/core/router/app_router.dart';
import 'package:cramly/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('signed-out restoration redirects from splash to login', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Make sense of what you study.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
