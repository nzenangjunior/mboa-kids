import 'package:go_router/go_router.dart';

import '../features/alphabet/alphabet_game_screen.dart';
import '../features/daily_path/daily_path_screen.dart';
import '../features/debug/progress_debug_screen.dart';
import '../features/home/home_screen.dart';
import '../features/rewards/bravo_result.dart';
import '../features/rewards/bravo_screen.dart';
import '../features/rewards/sticker_album_screen.dart';
import '../features/tracing/tracing_game_screen.dart';
import '../features/world_select/world_select_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/world',
      builder: (context, state) => const WorldSelectScreen(),
    ),
    GoRoute(
      path: '/daily-path',
      builder: (context, state) => const DailyPathScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const AlphabetGameScreen(),
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
      builder: (context, state) => const TracingGameScreen(),
    ),
    GoRoute(
      path: '/debug/progress',
      builder: (context, state) => const ProgressDebugScreen(),
    ),
  ],
);
