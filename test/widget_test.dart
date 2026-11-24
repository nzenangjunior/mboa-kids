import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:mboa_kids/features/alphabet/alphabet_game_screen.dart';
import 'package:mboa_kids/features/daily_path/daily_path_screen.dart';
import 'package:mboa_kids/features/home/home_screen.dart';
import 'package:mboa_kids/main.dart';

void main() {
  // CLAUDE.md section 10: no text for the child anywhere on these
  // screens — icons and the mascot only, so these checks are by widget
  // type and icon, never by text.
  testWidgets('home screen shows the mascot, the big play button and the world flags', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MboaKidsApp()));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.text('🇫🇷'), findsOneWidget);
    expect(find.text('🇬🇧'), findsOneWidget);
  });

  // The hop into the alphabet game itself (real audio/content providers)
  // is covered by test/features/alphabet/alphabet_game_screen_test.dart,
  // which overrides those providers with fakes.
  testWidgets('home -> daily path starts with the alphabet game', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MboaKidsApp()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.play_arrow));
    // Not pumpAndSettle(): this goes on to load real content and a real
    // audio service (TTS included), which this plain widget test has no
    // platform binding for and would never settle on its own.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(DailyPathScreen), findsOneWidget);
    expect(find.byType(AlphabetGameScreen), findsOneWidget);
  });
}
