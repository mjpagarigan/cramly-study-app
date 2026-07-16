import 'package:cramly/core/auth/auth_providers.dart';
import 'package:cramly/core/theme/app_colors.dart';
import 'package:cramly/core/theme/app_theme.dart';
import 'package:cramly/core/theme/theme_controller.dart';
import 'package:cramly/features/auth/login_screen.dart';
import 'package:cramly/features/auth/splash_screen.dart';
import 'package:cramly/features/profile/profile_screen.dart';
import 'package:cramly/shared/widgets/main_shell.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Learning Trace palettes expose the approved brand colors', () {
    expect(AppColors.light.background, const Color(0xFFF4F7F5));
    expect(AppColors.light.surface, const Color(0xFFFFFFFF));
    expect(AppColors.light.primary, const Color(0xFF24594B));
    expect(AppColors.light.poppy, const Color(0xFFC43F32));
    expect(AppColors.dark.background, const Color(0xFF101713));
    expect(AppColors.dark.surface, const Color(0xFF17211D));
    expect(AppColors.dark.primary, const Color(0xFF78B69E));
    expect(AppColors.dark.poppy, const Color(0xFFEF7464));
  });

  test(
    'appearance defaults to system and persists an explicit choice',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final controller = ThemeController(preferences);

      expect(controller.state, ThemeMode.system);
      await controller.set(ThemeMode.dark);
      expect(controller.state, ThemeMode.dark);
      expect(preferences.getString('theme_mode'), 'dark');
    },
  );

  testWidgets('registration requires eight password characters', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create an account'));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Use at least 8 characters.'), findsOneWidget);
  });

  testWidgets('splash exposes a retry state when session restoration fails', (
    tester,
  ) async {
    _useMobileViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream<User?>.error(StateError('offline')),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const SplashScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('We could not restore your session.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('profile keeps planned account features truthful', (
    tester,
  ) async {
    _useMobileViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(preferences),
          currentUserProvider.overrideWith((ref) => null),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Edit account'), findsOneWidget);
    expect(find.text('Apple sign-in'), findsOneWidget);
    expect(find.text('Planned'), findsNWidgets(2));
  });

  testWidgets('shell navigation and FAB appear only on root screens', (
    tester,
  ) async {
    _useMobileViewport(tester);
    Widget page(String label) => Scaffold(body: Text(label));
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, state, shell) =>
              MainShell(navigationShell: shell, location: state.uri.path),
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/home', builder: (_, _) => page('root'))],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/library',
                  builder: (_, _) => page('library root'),
                  routes: [
                    GoRoute(path: 'detail', builder: (_, _) => page('detail')),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/study', builder: (_, _) => page('study')),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/progress', builder: (_, _) => page('progress')),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/profile', builder: (_, _) => page('profile')),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    router.go('/library/detail');
    await tester.pumpAndSettle();

    expect(find.text('detail'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}

void _useMobileViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
