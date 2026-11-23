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
import 'package:mboa_kids/core/progress/progress_repository.dart';
import 'package:mboa_kids/core/rewards/sticker_catalog.dart';
import 'package:mboa_kids/core/tracing/tracing_glyph.dart';
import 'package:mboa_kids/features/rewards/bravo_result.dart';
import 'package:mboa_kids/features/rewards/bravo_screen.dart';
import 'package:mboa_kids/features/tracing/tracing_canvas_painter.dart';
import 'package:mboa_kids/features/tracing/tracing_game_screen.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final content = files[key];
    if (content == null) {
      throw FlutterError('Asset not found: $key');
    }
    final bytes = utf8.encode(content);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

class _FakeAudioService implements AudioService {
  @override
  Future<void> playItem(String itemId) async {}

  @override
  Future<void> playPrompt(String key) async {}

  @override
  Future<void> playSfx(String name) async {}

  @override
  Future<void> playPraise() async {}

  @override
  Future<void> stop() async {}
}

/// Records every item id the screen asks to have spoken, in order — this
/// is how the tests below check exactly which letters, and in what order
/// (repeats included), the activity actually requested.
class _RecordingAudioService implements AudioService {
  final List<String> playedItemIds = [];

  @override
  Future<void> playItem(String itemId) async => playedItemIds.add(itemId);

  @override
  Future<void> playPrompt(String key) async {}

  @override
  Future<void> playSfx(String name) async {}

  @override
  Future<void> playPraise() async {}

  @override
  Future<void> stop() async {}
}

String _letterJson(String glyph, {String word = 'mot'}) {
  final lower = glyph.toLowerCase();
  return '''
    { "id": "fr.letter.$glyph", "glyph": "$glyph", "lower": "$lower", "audio": "audio/fr/letters/$lower.ogg",
      "word": { "label": "$word", "image": "images/vocab/$word.webp", "audio": "audio/fr/words/$word.ogg" } }
''';
}

String _alphabetJsonFor(List<String> glyphs) => '''
{
  "world": "fr",
  "module": "alphabet",
  "packSize": 3,
  "items": [${glyphs.map(_letterJson).join(',')}]
}
''';

const _alphabetJson = '''
{
  "world": "fr",
  "module": "alphabet",
  "packSize": 3,
  "items": [
    { "id": "fr.letter.A", "glyph": "A", "lower": "a", "audio": "audio/fr/letters/a.ogg",
      "word": { "label": "abeille", "image": "images/vocab/abeille.webp", "audio": "audio/fr/words/abeille.ogg" } },
    { "id": "fr.letter.B", "glyph": "B", "lower": "b", "audio": "audio/fr/letters/b.ogg",
      "word": { "label": "balle", "image": "images/vocab/balle.webp", "audio": "audio/fr/words/balle.ogg" } }
  ]
}
''';

/// Covers every letter of "ESTRELLA" so a test can trace the whole name,
/// repeats (E and L) included.
final _estrellaAlphabetJson = _alphabetJsonFor(['A', 'E', 'L', 'R', 'S', 'T']);

/// Both glyphs are the same simple horizontal line: easy to drag along
/// precisely in a test, without needing to replicate the real curvy
/// letter shapes from `assets/content/tracing/letters.json`.
final _straightLineGlyph = TracingGlyph(
  glyph: 'line',
  strokes: const [
    TracingStroke([TracingPoint(0.1, 0.5), TracingPoint(0.9, 0.5)]),
  ],
);

/// `writeMax: 0` so no test here accidentally picks up a number item —
/// the number-specific test overrides this explicitly.
const _noNumbersJson = '''
{
  "world": "fr",
  "recognize": [[0, 20]],
  "countObjectsMax": 20,
  "writeMax": 0,
  "countByTensMax": 100
}
''';

Widget _buildTestApp({
  AudioService? audioService,
  String alphabetJson = _alphabetJson,
  String numbersJson = _noNumbersJson,
  String childFirstName = 'AB',
  Map<String, TracingGlyph>? glyphs,
  ProgressRepository? repository,
  int dayOffset = 0,
}) {
  return ProviderScope(
    // A fresh key per build: two sequential pumpWidget() calls at the same
    // widget position would otherwise let Flutter reuse the same
    // ProviderScope element, which keeps its old container (and anything
    // already resolved in it, e.g. a FutureProvider's cached value) alive
    // even though the `overrides` list below changed — exactly the kind
    // of stale state a test simulating two separate sessions must avoid.
    key: UniqueKey(),
    overrides: [
      worldProvider.overrideWith((ref) => 'fr'),
      simulatedDayOffsetProvider.overrideWith((ref) => dayOffset),
      contentLoaderProvider.overrideWithValue(
        ContentLoader(
          _FakeAssetBundle({
            'assets/content/fr/alphabet.json': alphabetJson,
            'assets/content/fr/numbers.json': numbersJson,
          }),
        ),
      ),
      audioServiceProvider(
        'fr',
      ).overrideWith((ref) async => audioService ?? _FakeAudioService()),
      progressRepositoryProvider.overrideWithValue(
        repository ?? DriftProgressRepository(ProgressDatabase(NativeDatabase.memory())),
      ),
      // Not the real asset: `rootBundle.loadString` for the same path
      // hangs on the 2nd+ call within one test file's process (confirmed
      // by reproducing it here — see the test report), unrelated to this
      // app's own code. Real widget/integration tests should never depend
      // on repeat real-asset loads within one process; a fake avoids it.
      stickerCatalogListProvider.overrideWith(
        (ref) async => const [GameSticker(id: 'sticker.test', emoji: '⭐')],
      ),
      tracingContentProvider.overrideWith(
        (ref) async => TracingContent(
          glyphs ?? {'A': _straightLineGlyph, 'B': _straightLineGlyph},
        ),
      ),
      // Every letter traced in these tests comes from the "first name" so
      // no test needs to seed progression state to make them eligible.
      childFirstNameProvider.overrideWithValue(childFirstName),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const TracingGameScreen()),
          GoRoute(
            path: '/bravo',
            builder: (context, state) => BravoScreen(result: state.extra as BravoResult?),
          ),
        ],
      ),
    ),
  );
}

/// Drags a finger through every point of [screenPoints] in order, pumping
/// between moves so onPanUpdate actually fires for each one (CLAUDE.md
/// section 10: tracing must recognize a real, continuous finger stroke).
Future<void> _dragAlong(WidgetTester tester, List<Offset> screenPoints) async {
  final gesture = await tester.startGesture(screenPoints.first);
  for (final point in screenPoints.skip(1)) {
    await gesture.moveTo(point);
    await tester.pump(const Duration(milliseconds: 10));
  }
  await gesture.up();
  await tester.pump();
}

List<Offset> _lineScreenPoints(Rect canvas, {int steps = 16}) {
  return [
    for (var i = 0; i <= steps; i++)
      canvas.topLeft + Offset(canvas.width * (0.1 + 0.8 * i / steps), canvas.height * 0.5),
  ];
}

/// Flutter's own Material widgets (buttons, ripples...) also use
/// [CustomPaint] internally, so a bare `find.byType(CustomPaint)` can match
/// the wrong one; this finds the tracing canvas specifically.
Finder _findTracingCanvas() {
  return find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is TracingCanvasPainter,
  );
}

TracingCanvasPainter _currentPainter(WidgetTester tester) {
  final widget = tester.widget<CustomPaint>(_findTracingCanvas());
  return widget.painter as TracingCanvasPainter;
}

/// Traces the current item once (one pass now — guided or unguided is
/// decided per item, not two passes per item, CLAUDE.md section 10).
/// [isLastOfActivity] controls whether this is the very last successful
/// trace of the session, in which case the screen goes on to the Bravo
/// screen instead of showing the next guide (and plays confetti, whose
/// ticker never settles on its own, so a bounded pump is used instead of
/// pumpAndSettle()).
Future<void> _traceCurrentItem(WidgetTester tester, {required bool isLastOfActivity}) async {
  final canvasRect = tester.getRect(_findTracingCanvas());
  await _dragAlong(tester, _lineScreenPoints(canvasRect));
  await tester.pump(const Duration(milliseconds: 1700));
  if (isLastOfActivity) {
    await tester.pump(const Duration(milliseconds: 500));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('shows the tracing canvas and mascot once content has loaded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(_findTracingCanvas(), findsOneWidget);
  });

  testWidgets('a good trace advances straight to the next letter (one pass per item)', (
    WidgetTester tester,
  ) async {
    final audio = _RecordingAudioService();
    await tester.pumpWidget(_buildTestApp(audioService: audio));
    await tester.pumpAndSettle();

    expect(audio.playedItemIds, ['fr.letter.A']);
    expect(_currentPainter(tester).showGuide, isTrue);

    await _traceCurrentItem(tester, isLastOfActivity: false);

    expect(
      audio.playedItemIds,
      ['fr.letter.A', 'fr.letter.B'],
      reason: 'one successful trace is enough to move to the next letter',
    );
    expect(find.text('Accueil'), findsNothing);
  });

  testWidgets(
    'tracing every letter finishes the activity and reaches the Bravo '
    'screen with stars and a sticker',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await _traceCurrentItem(tester, isLastOfActivity: false); // "A"
      expect(find.text('Accueil'), findsNothing);

      await _traceCurrentItem(tester, isLastOfActivity: true); // "B"

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsWidgets);
    },
  );

  testWidgets('a scribble far from the letter does not advance it, and replays the stroke', (
    WidgetTester tester,
  ) async {
    final audio = _RecordingAudioService();
    await tester.pumpWidget(_buildTestApp(audioService: audio));
    await tester.pumpAndSettle();

    final canvasRect = tester.getRect(_findTracingCanvas());
    final corner = canvasRect.topLeft + const Offset(10, 10);
    final gesture = await tester.startGesture(corner);
    for (var i = 0; i < 5; i++) {
      await gesture.moveTo(corner + Offset(i * 2.0, 0));
      await tester.pump(const Duration(milliseconds: 10));
    }
    await gesture.up();
    await tester.pump();
    // The replay animation (the mascot "re-showing" the stroke after a
    // failed attempt, CLAUDE.md section 10) has a bounded duration, so it
    // settles on its own like any other finite animation.
    await tester.pumpAndSettle();

    expect(find.text('Accueil'), findsNothing);
    expect(_findTracingCanvas(), findsOneWidget);
    expect(
      audio.playedItemIds,
      ['fr.letter.A', 'fr.letter.A'],
      reason: 'a failed attempt replays the prompt for the same letter, '
          'it does not advance to a new one',
    );
  });

  testWidgets(
    'an item traced with the guide stays guided the rest of the same day, '
    'even across a new session, and only drops the guide the next day',
    (WidgetTester tester) async {
      final repository = DriftProgressRepository(ProgressDatabase(NativeDatabase.memory()));
      final glyphs = {'A': _straightLineGlyph};

      // Day 0, session 1: never traced before, so guided.
      await tester.pumpWidget(
        _buildTestApp(
          alphabetJson: _alphabetJsonFor(['A']),
          childFirstName: 'A',
          glyphs: glyphs,
          repository: repository,
          dayOffset: 0,
        ),
      );
      await tester.pumpAndSettle();
      expect(_currentPainter(tester).showGuide, isTrue);
      await _traceCurrentItem(tester, isLastOfActivity: true);

      // Day 0, session 2 (new screen instance, same repository, same
      // calendar day): still guided — never in the same session/day.
      await tester.pumpWidget(
        _buildTestApp(
          alphabetJson: _alphabetJsonFor(['A']),
          childFirstName: 'A',
          glyphs: glyphs,
          repository: repository,
          dayOffset: 0,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _currentPainter(tester).showGuide,
        isTrue,
        reason: 'a guided success earlier today must not unlock "sans guide" today',
      );
      await _traceCurrentItem(tester, isLastOfActivity: true);

      // Day 1: the guided success happened on an earlier day, so now it
      // is offered without the guide.
      await tester.pumpWidget(
        _buildTestApp(
          alphabetJson: _alphabetJsonFor(['A']),
          childFirstName: 'A',
          glyphs: glyphs,
          repository: repository,
          dayOffset: 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _currentPainter(tester).showGuide,
        isFalse,
        reason: 'a guided success on an earlier day unlocks "sans guide" today',
      );
    },
  );

  testWidgets(
    'at most 5 items are traced per session, and the next session resumes '
    'right after where this one left off (wrapping past the end)',
    (WidgetTester tester) async {
      final repository = DriftProgressRepository(ProgressDatabase(NativeDatabase.memory()));
      final glyphs = {for (final g in 'ABCDEFG'.split('')) g: _straightLineGlyph};

      await tester.pumpWidget(
        _buildTestApp(
          alphabetJson: _alphabetJsonFor('ABCDEFG'.split('')),
          childFirstName: 'ABCDEFG',
          glyphs: glyphs,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      // Session 1: exactly 5 of the 7 eligible letters (A-E), then Bravo.
      for (var i = 0; i < 5; i++) {
        await _traceCurrentItem(tester, isLastOfActivity: i == 4);
      }
      expect(find.text('Accueil'), findsOneWidget, reason: 'session 1 stops at 5 traces');

      // Session 2 (fresh screen, same repository): resumes at F, G, then
      // wraps back to the start (A, B, C) — never restarts from A.
      final audio = _RecordingAudioService();
      await tester.pumpWidget(
        _buildTestApp(
          audioService: audio,
          alphabetJson: _alphabetJsonFor('ABCDEFG'.split('')),
          childFirstName: 'ABCDEFG',
          glyphs: glyphs,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();
      expect(audio.playedItemIds, ['fr.letter.F']);

      for (var i = 0; i < 5; i++) {
        await _traceCurrentItem(tester, isLastOfActivity: i == 4);
      }

      expect(
        audio.playedItemIds,
        [
          'fr.letter.F',
          'fr.letter.G',
          'fr.letter.A',
          'fr.letter.B',
          'fr.letter.C',
        ],
        reason: 'session 2 continues from F, not from A again, and wraps '
            'once it reaches the end of the 7 eligible letters',
      );
      expect(find.text('Accueil'), findsOneWidget);
    },
  );

  testWidgets(
    'tracing the name ESTRELLA across sessions requests every letter once '
    'per occurrence, repeats (E and L) included, with no letter skipped '
    'or reused between sessions',
    (WidgetTester tester) async {
      final repository = DriftProgressRepository(ProgressDatabase(NativeDatabase.memory()));
      final audio = _RecordingAudioService();
      final glyphs = {
        for (final letter in ['A', 'E', 'L', 'R', 'S', 'T']) letter: _straightLineGlyph,
      };

      await tester.pumpWidget(
        _buildTestApp(
          audioService: audio,
          alphabetJson: _estrellaAlphabetJson,
          childFirstName: 'ESTRELLA',
          glyphs: glyphs,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      // ESTRELLA is 8 letters, capped at 5 per session: E, S, T, R, E.
      expect(audio.playedItemIds, ['fr.letter.E']);
      for (var i = 0; i < 5; i++) {
        await _traceCurrentItem(tester, isLastOfActivity: i == 4);
      }
      expect(
        audio.playedItemIds,
        ['fr.letter.E', 'fr.letter.S', 'fr.letter.T', 'fr.letter.R', 'fr.letter.E'],
      );
      expect(find.text('Accueil'), findsOneWidget);

      // Next session resumes right after the *second* E, at L, L, A, then
      // wraps to E, S — the second E is not skipped nor retraced twice.
      final audio2 = _RecordingAudioService();
      await tester.pumpWidget(
        _buildTestApp(
          audioService: audio2,
          alphabetJson: _estrellaAlphabetJson,
          childFirstName: 'ESTRELLA',
          glyphs: glyphs,
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();
      expect(audio2.playedItemIds, ['fr.letter.L']);

      for (var i = 0; i < 5; i++) {
        await _traceCurrentItem(tester, isLastOfActivity: i == 4);
      }
      expect(
        audio2.playedItemIds,
        [
          'fr.letter.L',
          'fr.letter.L',
          'fr.letter.A',
          'fr.letter.E',
          'fr.letter.S',
        ],
      );
    },
  );

  testWidgets('numbers 1 to writeMax are offered after the letters', (
    WidgetTester tester,
  ) async {
    final audio = _RecordingAudioService();
    final glyphs = {'A': _straightLineGlyph, '1': _straightLineGlyph, '2': _straightLineGlyph};

    await tester.pumpWidget(
      _buildTestApp(
        audioService: audio,
        alphabetJson: _alphabetJson,
        numbersJson: '''
{
  "world": "fr",
  "recognize": [[0, 20]],
  "countObjectsMax": 20,
  "writeMax": 2,
  "countByTensMax": 100
}
''',
        childFirstName: 'A',
        glyphs: glyphs,
      ),
    );
    await tester.pumpAndSettle();

    expect(audio.playedItemIds, ['fr.letter.A']);

    await _traceCurrentItem(tester, isLastOfActivity: false);
    expect(audio.playedItemIds.last, 'fr.number.1');

    await _traceCurrentItem(tester, isLastOfActivity: false);
    expect(audio.playedItemIds.last, 'fr.number.2');

    await _traceCurrentItem(tester, isLastOfActivity: true);
    expect(find.text('Accueil'), findsOneWidget);
  });
}
