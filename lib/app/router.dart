import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/tracing/tracing_queue.dart';
import '../features/alphabet/alphabet_game_screen.dart';
import '../features/daily_path/daily_path_screen.dart';
import '../features/daily_path/mascot_sleeping_screen.dart';
import '../features/debug/progress_debug_screen.dart';
import '../features/home/home_screen.dart';
import '../features/islands/island_map_screen.dart';
import '../features/islands/level_path_screen.dart';
import '../features/rewards/bravo_result.dart';
import '../features/rewards/bravo_screen.dart';
import '../features/rewards/sticker_album_screen.dart';
import '../features/tracing/tracing_game_screen.dart';

/// Arguments for the `/tracing` route when it targets one level on the
/// path (CLAUDE.md section 10) rather than the automatic daily queue.
class TracingRouteArgs {
  const TracingRouteArgs({required this.explicitItems, required this.levelId});

  final List<TracingQueueItem> explicitItems;
  final String levelId;
}

/// A light fade + scale between every screen (CLAUDE.md section 10,
/// Refonte visuelle: "transitions animées entre les écrans"), short
/// enough to stay snappy on entry-level Android hardware.
Page<void> _transitionPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _transitionPage(const HomeScreen(), state),
    ),
    GoRoute(
      path: '/daily-path',
      pageBuilder: (context, state) => _transitionPage(const DailyPathScreen(), state),
    ),
    GoRoute(
      path: '/mascot-sleeping',
      pageBuilder: (context, state) => _transitionPage(const MascotSleepingScreen(), state),
    ),
    GoRoute(
      path: '/islands',
      pageBuilder: (context, state) => _transitionPage(const IslandMapScreen(), state),
    ),
    GoRoute(
      path: '/islands/alphabet',
      pageBuilder: (context, state) => _transitionPage(
        const LevelPathScreen(islandType: IslandType.alphabet),
        state,
      ),
    ),
    GoRoute(
      path: '/islands/tracing',
      pageBuilder: (context, state) => _transitionPage(
        const LevelPathScreen(islandType: IslandType.tracing),
        state,
      ),
    ),
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) =>
          _transitionPage(AlphabetGameScreen(packNumber: state.extra as int?), state),
    ),
    GoRoute(
      path: '/bravo',
      pageBuilder: (context, state) =>
          _transitionPage(BravoScreen(result: state.extra as BravoResult?), state),
    ),
    GoRoute(
      path: '/album',
      pageBuilder: (context, state) => _transitionPage(const StickerAlbumScreen(), state),
    ),
    GoRoute(
      path: '/tracing',
      pageBuilder: (context, state) {
        final args = state.extra as TracingRouteArgs?;
        return _transitionPage(
          TracingGameScreen(explicitItems: args?.explicitItems, levelId: args?.levelId),
          state,
        );
      },
    ),
    GoRoute(
      path: '/debug/progress',
      pageBuilder: (context, state) => _transitionPage(const ProgressDebugScreen(), state),
    ),
  ],
);
