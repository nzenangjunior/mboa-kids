import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mboa_kids/app/providers.dart';
import 'package:mboa_kids/core/audio/audio_service.dart';
import 'package:mboa_kids/core/content/content_loader.dart';
import 'package:mboa_kids/core/progress/drift_progress_repository.dart';
import 'package:mboa_kids/core/progress/progress_database.dart';
import 'package:mboa_kids/core/rewards/sticker_catalog.dart';
import 'package:mboa_kids/core/tracing/tracing_glyph.dart';
import 'package:mboa_kids/features/alphabet/alphabet_game_screen.dart';
import 'package:mboa_kids/features/daily_path/daily_path_screen.dart';
import 'package:mboa_kids/features/rewards/bravo_result.dart';
import 'package:mboa_kids/features/rewards/bravo_screen.dart';
import 'package:mboa_kids/features/tracing/tracing_canvas_painter.dart';
import 'package:mboa_kids/features/tracing/tracing_game_screen.dart';
import 'package:mboa_kids/shared/widgets/choice_card.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final content = files[key];
    if (content == null) throw FlutterError('Asset not found: $key');
    return ByteData.view(Uint8List.fromList(utf8.encode(content)).buffer);
  }
}

class _FakeAudioService implements AudioService {
  final List<String> promptCalls = [];

  @override
  Future<void> playItem(String itemId) async {}
  @override
  Future<void> playPrompt(String key) async {
    promptCalls.add(key);
  }
  @override
  Future<void> playInstruction({required String promptKey, required String itemId}) async {}
  @override
  Future<void> playSfx(String name) async {}
  @override
  Future<void> playPraise() async {}
  @override
  Future<void> stop() async {}
}

const _alphabetJson = '''
{
  "world": "fr",
  "module": "alphabet",
  "packSize": 3,
  "items": [
    { "id": "fr.letter.A", "glyph": "A", "lower": "a", "audio": "audio/fr/letters/a.ogg",
      "word": { "label": "abeille", "image": "images/vocab/abeille.webp", "audio": "audio/fr/words/abeille.ogg" } },
    { "id": "fr.letter.B", "glyph": "B", "lower": "b", "audio": "audio/fr/letters/b.ogg",
      "word": { "label": "balle", "image": "images/vocab/balle.webp", "audio": "audio/fr/words/balle.ogg" } },
    { "id": "fr.letter.C", "glyph": "C", "lower": "c", "audio": "audio/fr/letters/c.ogg",
      "word": { "label": "chat", "image": "images/vocab/chat.webp", "audio": "audio/fr/words/chat.ogg" } }
  ]
}
''';

const _noNumbersJson = '''
{
  "world": "fr",
  "recognize": [[0, 20]],
  "countObjectsMax": 20,
  "writeMax": 0,
  "countByTensMax": 100
}
''';

final _straightLineGlyph = TracingGlyph(
  glyph: 'line',
  strokes: const [
    TracingStroke([TracingPoint(0.1, 0.5), TracingPoint(0.9, 0.5)]),
  ],
);

Widget _buildTestApp({
  Duration? sessionDuration,
  int dayOffset = 0,
  AudioService? audioService,
}) {
  return ProviderScope(
    overrides: [
      worldProvider.overrideWith((ref) => 'fr'),
      simulatedDayOffsetProvider.overrideWith((ref) => dayOffset),
      sessionDurationProvider.overrideWithValue(sessionDuration ?? const Duration(minutes: 10)),
      contentLoaderProvider.overrideWithValue(
        ContentLoader(
          _FakeAssetBundle({
            'assets/content/fr/alphabet.json': _alphabetJson,
            'assets/content/fr/numbers.json': _noNumbersJson,
          }),
        ),
      ),
      audioServiceProvider('fr').overrideWith((ref) async => audioService ?? _FakeAudioService()),
      progressRepositoryProvider.overrideWithValue(
        DriftProgressRepository(ProgressDatabase(NativeDatabase.memory())),
      ),
      stickerCatalogListProvider.overrideWith(
        (ref) async => const [GameSticker(id: 'sticker.test', emoji: '⭐')],
      ),
      tracingContentProvider.overrideWith(
        (ref) async => TracingContent({'A': _straightLineGlyph}),
      ),
      childFirstNameProvider.overrideWithValue('A'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const DailyPathScreen()),
          GoRoute(
            path: '/bravo',
            builder: (context, state) => BravoScreen(result: state.extra as BravoResult?),
          ),
        ],
      ),
    ),
  );
}

Future<void> _answerEveryAlphabetRound(WidgetTester tester) async {
  // 40, not 20: matches the margin alphabet_game_screen_test.dart's own
  // "playing through the whole game" test uses — blindly cycling choices
  // can need several extra rounds before landing on the correct one.
  for (var attempt = 0; attempt < 40; attempt++) {
    if (find.byType(TracingGameScreen).evaluate().isNotEmpty) return;
    if (find.byType(BravoScreen).evaluate().isNotEmpty) return;
    final cards = find.byType(ChoiceCard);
    if (cards.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
      continue;
    }
    final count = tester.widgetList<ChoiceCard>(cards).length;
    await tester.tap(cards.at(attempt % count));
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _traceTheOneTracingItem(WidgetTester tester) async {
  final canvasFinder = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is TracingCanvasPainter,
  );
  final canvasRect = tester.getRect(canvasFinder);
  final gesture = await tester.startGesture(
    canvasRect.topLeft + Offset(canvasRect.width * 0.1, canvasRect.height * 0.5),
  );
  for (var i = 1; i <= 16; i++) {
    await gesture.moveTo(
      canvasRect.topLeft + Offset(canvasRect.width * (0.1 + 0.8 * i / 16), canvasRect.height * 0.5),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 1700));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('chains one alphabet game then one tracing session, ending on Bravo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump(const Duration(milliseconds: 100));
    // Past the 2s step-indicator intro overlay, which otherwise blocks
    // every tap underneath it (CLAUDE.md section 10, Refonte visuelle).
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(AlphabetGameScreen), findsOneWidget);

    await _answerEveryAlphabetRound(tester);
    expect(
      find.byType(TracingGameScreen),
      findsOneWidget,
      reason: 'after the alphabet game, the daily path moves to tracing',
    );
    // Past the step-indicator transition overlay between the two phases.
    await tester.pump(const Duration(seconds: 2));

    await _traceTheOneTracingItem(tester);

    expect(find.byType(BravoScreen), findsOneWidget);
    expect(find.byIcon(Icons.star), findsWidgets);
  });

  testWidgets(
    'stops at the alphabet game and skips tracing once the session duration is used up',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp(sessionDuration: Duration.zero));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      await _answerEveryAlphabetRound(tester);

      expect(
        find.byType(TracingGameScreen),
        findsNothing,
        reason: 'the configured duration was already used up after the alphabet game',
      );
      expect(find.byType(BravoScreen), findsOneWidget);
    },
  );

  group('step indicator (CLAUDE.md section 10: lettres → tracé → étoile)', () {
    testWidgets(
      'shows the steps big and announced for 2s, then small for the rest of the alphabet game',
      (WidgetTester tester) async {
        final audio = _FakeAudioService();
        await tester.pumpWidget(_buildTestApp(audioService: audio));
        await tester.pump(const Duration(milliseconds: 100));

        // Big intro: all 3 step icons visible, announced once.
        expect(find.byIcon(Icons.abc), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(audio.promptCalls.where((c) => c == 'daily_path_intro').length, 1);
        expect(
          find.byType(ColoredBox),
          findsWidgets,
          reason: 'the intro is a full-screen overlay on top of the game',
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pump(const Duration(milliseconds: 100));

        // Small from then on: same 3 icons, but no more full-screen overlay.
        expect(find.byIcon(Icons.abc), findsOneWidget);
        expect(find.byIcon(Icons.edit), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.byType(ChoiceCard), findsWidgets, reason: 'the game itself is now reachable');
      },
    );

    testWidgets(
      'announces a transition and checks off the alphabet step once tracing starts',
      (WidgetTester tester) async {
        final audio = _FakeAudioService();
        await tester.pumpWidget(_buildTestApp(audioService: audio));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 2));

        await _answerEveryAlphabetRound(tester);
        expect(find.byType(TracingGameScreen), findsOneWidget);

        expect(
          audio.promptCalls.where((c) => c == 'daily_path_to_tracing').length,
          1,
          reason: 'a short transition is announced between the two steps',
        );
        expect(
          find.byIcon(Icons.check_circle),
          findsOneWidget,
          reason: 'the finished alphabet step is checked off',
        );

        await tester.pump(const Duration(seconds: 2));
        expect(
          find.byIcon(Icons.check_circle),
          findsOneWidget,
          reason: 'still checked off once the transition overlay is gone',
        );
      },
    );
  });
}
