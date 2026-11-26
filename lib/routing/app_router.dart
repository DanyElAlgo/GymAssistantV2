import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../home/home_shell.dart';
import '../training/camera_guide_screen.dart';
import '../training/choose_exercise_screen.dart';
import '../training/exercise.dart';
import '../training/framing_screen.dart';

/// Route paths, kept in one place so screens never spell them out.
abstract final class AppRoutes {
  /// P06, the Train tab of P05.
  static const train = '/train';

  /// P07 for [exercise].
  static String cameraGuide(Exercise exercise) => '$train/${exercise.code}/guide';

  /// P08 for [exercise].
  static String framing(Exercise exercise) => '$train/${exercise.code}/framing';
}

/// The app's navigation (Diseño §10.1).
///
/// The app opens straight on the Train tab of P05 without an account
/// (ADR-0002); P01 and the role-based redirects arrive with accounts in F3.
/// Training screens from P07 on cover the whole screen, without the bottom bar
/// (Diseño §10.3).
final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.train,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.train,
                builder: (context, state) => const ChooseExerciseScreen(),
                routes: [
                  GoRoute(
                    path: ':exercise/guide',
                    parentNavigatorKey: rootNavigatorKey,
                    redirect: (context, state) =>
                        _exerciseFromPath(state) == null ? AppRoutes.train : null,
                    builder: (context, state) => CameraGuideScreen(exercise: _exerciseFromPath(state)!),
                  ),
                  GoRoute(
                    path: ':exercise/framing',
                    parentNavigatorKey: rootNavigatorKey,
                    redirect: (context, state) =>
                        _exerciseFromPath(state) == null ? AppRoutes.train : null,
                    builder: (context, state) => FramingScreen(exercise: _exerciseFromPath(state)!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

Exercise? _exerciseFromPath(GoRouterState state) => Exercise.fromCode(state.pathParameters['exercise']!);
