import 'package:go_router/go_router.dart';

import '../core/tracing/tracing_queue.dart';
import '../features/alphabet/alphabet_game_screen.dart';
import '../features/daily_path/daily_path_screen.dart';
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

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/daily-path',
      builder: (context, state) => const DailyPathScreen(),
    ),
    GoRoute(
      path: '/islands',
      builder: (context, state) => const IslandMapScreen(),
    ),
    GoRoute(
      path: '/islands/alphabet',
      builder: (context, state) => const LevelPathScreen(islandType: IslandType.alphabet),
    ),
    GoRoute(
      path: '/islands/tracing',
      builder: (context, state) => const LevelPathScreen(islandType: IslandType.tracing),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) =>
          AlphabetGameScreen(packNumber: state.extra as int?),
    ),
    GoRoute(
      path: '/bravo',
      builder: (context, state) =>
          BravoScreen(result: state.extra as BravoResult?),
    ),
    GoRoute(
      path: '/album',
      builder: (context, state) => const StickerAlbumScreen(),
    ),
    GoRoute(
      path: '/tracing',
      builder: (context, state) {
        final args = state.extra as TracingRouteArgs?;
        return TracingGameScreen(explicitItems: args?.explicitItems, levelId: args?.levelId);
      },
    ),
    GoRoute(
      path: '/debug/progress',
      builder: (context, state) => const ProgressDebugScreen(),
    ),
  ],
);
