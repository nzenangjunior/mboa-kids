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
import 'package:mboa_kids/core/tracing/tracing_glyph.dart';
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

/// Both glyphs are the same simple horizontal line: easy to drag along
/// precisely in a test, without needing to replicate the real curvy
/// letter shapes from `assets/content/tracing/letters.json`.
final _straightLineGlyph = TracingGlyph(
  glyph: 'line',
  strokes: const [
    TracingStroke([TracingPoint(0.1, 0.5), TracingPoint(0.9, 0.5)]),
  ],
);

Widget _buildTestApp() {
  return ProviderScope(
    overrides: [
      worldProvider.overrideWith((ref) => 'fr'),
      contentLoaderProvider.overrideWithValue(
        ContentLoader(
          _FakeAssetBundle({'assets/content/fr/alphabet.json': _alphabetJson}),
        ),
      ),
      audioServiceProvider('fr').overrideWith((ref) async => _FakeAudioService()),
      progressRepositoryProvider.overrideWithValue(
        DriftProgressRepository(ProgressDatabase(NativeDatabase.memory())),
      ),
      tracingContentProvider.overrideWith(
        (ref) async => TracingContent({'A': _straightLineGlyph, 'B': _straightLineGlyph}),
      ),
      // Both letters come from the "first name" so the test doesn't need to
      // seed progression state to make them eligible.
      childFirstNameProvider.overrideWithValue('AB'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const TracingGameScreen()),
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

void main() {
  testWidgets('shows the tracing canvas and mascot once content has loaded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(_findTracingCanvas(), findsOneWidget);
  });

  testWidgets(
    'a good trace advances to the next letter, and tracing every letter finishes the activity',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      final canvasRect = tester.getRect(_findTracingCanvas());

      // First letter ("A"): trace it, advance.
      await _dragAlong(tester, _lineScreenPoints(canvasRect));
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      expect(find.text('Accueil'), findsNothing);

      // Second letter ("B"): trace it, the activity should then finish.
      // The finished screen plays confetti, whose ticker never settles on
      // its own, so this pumps a bounded duration instead of
      // pumpAndSettle().
      final secondCanvasRect = tester.getRect(_findTracingCanvas());
      await _dragAlong(tester, _lineScreenPoints(secondCanvasRect));
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Accueil'), findsOneWidget);
    },
  );

  testWidgets('a scribble far from the letter does not advance it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    final canvasRect = tester.getRect(_findTracingCanvas());
    final corner = canvasRect.topLeft + const Offset(10, 10);
    final gesture = await tester.startGesture(corner);
    for (var i = 0; i < 5; i++) {
      await gesture.moveTo(corner + Offset(i * 2.0, 0));
      await tester.pump(const Duration(milliseconds: 10));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.text('Accueil'), findsNothing);
    expect(_findTracingCanvas(), findsOneWidget);
  });
}
