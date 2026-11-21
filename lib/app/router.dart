import 'package:go_router/go_router.dart';

import '../features/daily_path/daily_path_screen.dart';
import '../features/game/game_screen.dart';
import '../features/home/home_screen.dart';
import '../features/rewards/bravo_screen.dart';
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
    GoRoute(path: '/game', builder: (context, state) => const GameScreen()),
    GoRoute(path: '/bravo', builder: (context, state) => const BravoScreen()),
  ],
);
