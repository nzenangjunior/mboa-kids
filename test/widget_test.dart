import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mboa_kids/features/daily_path/daily_path_screen.dart';
import 'package:mboa_kids/features/game/game_screen.dart';
import 'package:mboa_kids/features/home/home_screen.dart';
import 'package:mboa_kids/features/rewards/bravo_screen.dart';
import 'package:mboa_kids/features/world_select/world_select_screen.dart';
import 'package:mboa_kids/main.dart';

void main() {
  testWidgets('home screen shows the app title and a Jouer button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MboaKidsApp()));

    expect(find.text('Mboa Kids ABC & 123'), findsOneWidget);
    expect(find.text('Jouer'), findsOneWidget);
  });

  testWidgets('home -> world -> daily path -> game -> bravo -> home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MboaKidsApp()));

    await tester.tap(find.text('Jouer'));
    await tester.pumpAndSettle();
    expect(find.byType(WorldSelectScreen), findsOneWidget);

    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.byType(DailyPathScreen), findsOneWidget);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);

    await tester.tap(find.text('Bonne réponse !'));
    await tester.pumpAndSettle();
    expect(find.byType(BravoScreen), findsOneWidget);

    await tester.tap(find.text('Accueil'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
