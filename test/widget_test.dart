import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mboa_kids/features/daily_path/daily_path_screen.dart';
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

  // The hop into the alphabet game itself (real audio/content providers)
  // is covered by test/features/alphabet/alphabet_game_screen_test.dart,
  // which overrides those providers with fakes.
  testWidgets('home -> world -> daily path', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MboaKidsApp()));

    await tester.tap(find.text('Jouer'));
    await tester.pumpAndSettle();
    expect(find.byType(WorldSelectScreen), findsOneWidget);

    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.byType(DailyPathScreen), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
  });
}
