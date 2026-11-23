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
/// is how the test below checks exactly which letters, and in what order
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

/// Covers every letter of "ESTRELLA" so the test below can trace the whole
/// name, repeats (E and L) included.
const _estrellaAlphabetJson = '''
{
  "world": "fr",
  "module": "alphabet",
  "packSize": 3,
  "items": [
    { "id": "fr.letter.A", "glyph": "A", "lower": "a", "audio": "audio/fr/letters/a.ogg",
      "word": { "label": "abeille", "image": "images/vocab/abeille.webp", "audio": "audio/fr/words/abeille.ogg" } },
    { "id": "fr.letter.E", "glyph": "E", "lower": "e", "audio": "audio/fr/letters/e.ogg",
      "word": { "label": "etoile", "image": "images/vocab/etoile.webp", "audio": "audio/fr/words/etoile.ogg" } },
    { "id": "fr.letter.L", "glyph": "L", "lower": "l", "audio": "audio/fr/letters/l.ogg",
      "word": { "label": "lune", "image": "images/vocab/lune.webp", "audio": "audio/fr/words/lune.ogg" } },
    { "id": "fr.letter.R", "glyph": "R", "lower": "r", "audio": "audio/fr/letters/r.ogg",
      "word": { "label": "robot", "image": "images/vocab/robot.webp", "audio": "audio/fr/words/robot.ogg" } },
    { "id": "fr.letter.S", "glyph": "S", "lower": "s", "audio": "audio/fr/letters/s.ogg",
      "word": { "label": "soleil", "image": "images/vocab/soleil.webp", "audio": "audio/fr/words/soleil.ogg" } },
    { "id": "fr.letter.T", "glyph": "T", "lower": "t", "audio": "audio/fr/letters/t.ogg",
      "word": { "label": "tortue", "image": "images/vocab/tortue.webp", "audio": "audio/fr/words/tortue.ogg" } }
  ]
}
''';

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
}) {
  return ProviderScope(
    overrides: [
      worldProvider.overrideWith((ref) => 'fr'),
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
        DriftProgressRepository(ProgressDatabase(NativeDatabase.memory())),
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

/// Traces the current item once (CLAUDE.md section 10: every item is
/// traced twice — once with the guide, once without — before the
/// activity moves to the next one). [isLast] controls whether this is the
/// very last successful trace of the whole queue, in which case the
/// screen goes on to the Bravo screen instead of showing the next guide
/// (and plays confetti, whose ticker never settles on its own, so a
/// bounded pump is used instead of pumpAndSettle()).
Future<void> _traceCurrentStage(WidgetTester tester, {required bool isLastOfActivity}) async {
  final canvasRect = tester.getRect(_findTracingCanvas());
  await _dragAlong(tester, _lineScreenPoints(canvasRect));
  await tester.pump(const Duration(milliseconds: 1700));
  if (isLastOfActivity) {
    await tester.pump(const Duration(milliseconds: 500));
  } else {
    await tester.pumpAndSettle();
  }
}

/// Traces one whole queue item: the guided pass, then the unguided pass.
Future<void> _traceCurrentItem(WidgetTester tester, {required bool isLastOfActivity}) async {
  await _traceCurrentStage(tester, isLastOfActivity: false);
  await _traceCurrentStage(tester, isLastOfActivity: isLastOfActivity);
}

void main() {
  testWidgets('shows the tracing canvas and mascot once content has loaded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(_findTracingCanvas(), findsOneWidget);
  });

  testWidgets(
    'a good trace must be repeated once guided and once unguided before advancing',
    (WidgetTester tester) async {
      final audio = _RecordingAudioService();
      await tester.pumpWidget(_buildTestApp(audioService: audio));
      await tester.pumpAndSettle();

      expect(audio.playedItemIds, ['fr.letter.A']);

      // Guided pass succeeds: still on "A" (now unguided), not yet "B".
      await _traceCurrentStage(tester, isLastOfActivity: false);
      expect(
        audio.playedItemIds,
        ['fr.letter.A', 'fr.letter.A'],
        reason: 'the prompt for "A" is replayed when moving to the '
            'unguided pass of the same letter, not advanced to "B" yet',
      );
      expect(find.text('Accueil'), findsNothing);

      // Unguided pass succeeds: now "B" starts.
      await _traceCurrentStage(tester, isLastOfActivity: false);
      expect(audio.playedItemIds, ['fr.letter.A', 'fr.letter.A', 'fr.letter.B']);
      expect(find.text('Accueil'), findsNothing);
    },
  );

  testWidgets(
    'tracing every letter (guided and unguided) finishes the activity and '
    'reaches the Bravo screen with stars and a sticker',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // "A": both passes.
      await _traceCurrentItem(tester, isLastOfActivity: false);
      expect(find.text('Accueil'), findsNothing);

      // "B": both passes — the activity finishes after this.
      await _traceCurrentItem(tester, isLastOfActivity: true);

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
    'tracing the full first name requests every letter once per stage per '
    'occurrence, repeats included — ESTRELLA has E at positions 1 and 5, '
    'L at 6 and 7',
    (WidgetTester tester) async {
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
        ),
      );
      await tester.pumpAndSettle();

      const nameLetterIds = [
        'fr.letter.E',
        'fr.letter.S',
        'fr.letter.T',
        'fr.letter.R',
        'fr.letter.E',
        'fr.letter.L',
        'fr.letter.L',
        'fr.letter.A',
      ];
      // Each letter is prompted twice (guided, then unguided).
      final expectedIds = [for (final id in nameLetterIds) ...[id, id]];

      // The very first prompt (before any drag) already proves the queue
      // starts with the name's first letter.
      expect(audio.playedItemIds, [expectedIds.first]);

      for (var i = 0; i < nameLetterIds.length; i++) {
        await _traceCurrentItem(tester, isLastOfActivity: i == nameLetterIds.length - 1);
      }

      expect(
        audio.playedItemIds,
        expectedIds,
        reason: 'every letter of the name must be requested once per '
            'stage per occurrence, in order, with no repeat silently dropped',
      );
      expect(find.text('Accueil'), findsOneWidget);

      expect(
        audio.playedItemIds.where((id) => id == 'fr.letter.E').length,
        4,
        reason: 'E occurs twice in ESTRELLA, each occurrence prompted twice',
      );
      expect(
        audio.playedItemIds.where((id) => id == 'fr.letter.L').length,
        4,
        reason: 'L occurs twice in ESTRELLA, each occurrence prompted twice',
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
