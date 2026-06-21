import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:quiztech/app/shell/main_shell_page.dart';
import 'package:quiztech/features/auth/presentation/view/login_screen.dart';
import 'package:quiztech/features/auth/presentation/view/signup_screen.dart';
import 'package:quiztech/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:quiztech/features/home/presentation/view/home_screen.dart';
import 'package:quiztech/features/profile/presentation/view/profile_screen.dart';
import 'package:quiztech/features/quiz/domain/models/quiz_model.dart';
import 'package:quiztech/features/quiz/presentation/view/quiz_details_screen.dart';
import 'package:quiztech/features/quiz/presentation/view/quiz_play_screen.dart';
import 'package:quiztech/features/score/presentation/view/score_screen.dart';

import 'app_routes.dart';
import 'route_transitions.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>();
final _scoreNavigatorKey = GlobalKey<NavigatorState>();
final _profileNavigatorKey = GlobalKey<NavigatorState>();

/// The app's [GoRouter], wired to auth state for redirects.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authViewModelProvider);

      // Wait for the persisted session to load before deciding.
      if (!auth.isInitialized) return null;

      final location = state.matchedLocation;
      final onAuthPage =
          location == AppRoutes.login || location == AppRoutes.signup;

      if (!auth.isLoggedIn) return onAuthPage ? null : AppRoutes.login;
      if (onAuthPage) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignUpScreen(),
      ),

      // Main app: bottom-nav shell with 3 tab branches.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _scoreNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.score,
                builder: (context, state) => const ScoreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Quiz flow — pushed over the shell.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.quizDetails,
        pageBuilder: (context, state) => slideFadePage(
          state: state,
          child: QuizDetailsScreen(quizDetail: state.extra as QuizDetail),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.quizPlay,
        pageBuilder: (context, state) => slideFadePage(
          state: state,
          child: QuizPlayScreen(quizDetail: state.extra as QuizDetail),
        ),
      ),
    ],
  );
});

/// Bridges the Riverpod auth provider to GoRouter's [Listenable] refresh hook.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authViewModelProvider, (_, __) => notifyListeners());
  }
}
