import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/courses/screens/course_detail_screen.dart';
import '../../features/courses/screens/library_screen.dart';
import '../../features/decks/screens/deck_detail_screen.dart';
import '../../features/decks/screens/deck_review_screen.dart';
import '../../features/documents/screens/document_detail_screen.dart';
import '../../features/documents/screens/upload_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/study/study_screen.dart';
import '../../features/summaries/screens/summary_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../auth/auth_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loc = state.matchedLocation;
      final atSplash = loc == '/splash';
      final atLogin = loc == '/login';

      // A restoration failure is rendered with a retry action on Splash.
      if (authState.hasError && !authState.hasValue) {
        return atSplash ? null : '/splash';
      }

      // Auth state hasn't been restored from disk yet — sit on splash.
      if (!authState.hasValue) {
        return atSplash ? null : '/splash';
      }

      final user = authState.valueOrNull;

      // Auth restored, no user → login (unless already there).
      if (user == null) {
        return atLogin ? null : '/login';
      }

      // Auth restored, signed in → leave splash/login.
      if (atSplash || atLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/upload',
        builder: (_, state) => UploadScreen(
          preselectedCourseId: state.uri.queryParameters['courseId'],
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, state, navigationShell) => MainShell(
          navigationShell: navigationShell,
          location: state.uri.path,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (_, _) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => CourseDetailScreen(
                      courseId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'deck/:deckId',
                        builder: (_, state) => DeckDetailScreen(
                          deckId: state.pathParameters['deckId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'review',
                            builder: (_, state) => DeckReviewScreen(
                              deckId: state.pathParameters['deckId']!,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'doc/:docId',
                        builder: (_, state) => DocumentDetailScreen(
                          documentId: state.pathParameters['docId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'summary/:summaryId',
                            builder: (_, state) => SummaryScreen(
                              summaryId: state.pathParameters['summaryId']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/study', builder: (_, _) => const StudyScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (_, _) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
