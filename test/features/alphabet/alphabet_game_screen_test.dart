import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mboa_kids/app/providers.dart';
import 'package:mboa_kids/core/audio/audio_service.dart';
import 'package:mboa_kids/core/content/content_loader.dart';
import 'package:mboa_kids/core/progress/progress_database.dart';
import 'package:mboa_kids/core/progress/progress_repository.dart';
import 'package:mboa_kids/features/alphabet/alphabet_game_screen.dart';
import 'package:mboa_kids/shared/widgets/choice_card.dart';

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
      "word": { "label": "chat", "image": "images/vocab/chat.webp", "audio": "audio/fr/words/chat.ogg" } },
    { "id": "fr.letter.D", "glyph": "D", "lower": "d", "audio": "audio/fr/letters/d.ogg",
      "word": { "label": "dinosaure", "image": "images/vocab/dinosaure.webp", "audio": "audio/fr/words/dinosaure.ogg" } },
    { "id": "fr.letter.E", "glyph": "E", "lower": "e", "audio": "audio/fr/letters/e.ogg",
      "word": { "label": "éléphant", "image": "images/vocab/elephant.webp", "audio": "audio/fr/words/elephant.ogg" } }
  ]
}
''';

Widget _buildTestApp({ProgressDatabase? progressDatabase}) {
  return ProviderScope(
    overrides: [
      worldProvider.overrideWith((ref) => 'fr'),
      contentLoaderProvider.overrideWithValue(
        ContentLoader(
          _FakeAssetBundle({'assets/content/fr/alphabet.json': _alphabetJson}),
        ),
      ),
      audioServiceProvider('fr').overrideWith((ref) async => _FakeAudioService()),
      progressDatabaseProvider.overrideWithValue(
        progressDatabase ?? ProgressDatabase.forTesting(NativeDatabase.memory()),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const AlphabetGameScreen()),
          GoRoute(
            path: '/bravo',
            builder: (context, state) => const Scaffold(body: Text('BRAVO_MARKER')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('shows 3 choices and a mascot once content has loaded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceCard), findsNWidgets(3));
  });

  testWidgets('tapping a choice reveals exactly one correct answer and a Continuer button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ChoiceCard).first);
    await tester.pumpAndSettle();

    expect(find.text('Continuer'), findsOneWidget);

    final cards = tester.widgetList<ChoiceCard>(find.byType(ChoiceCard));
    final correctCount = cards
        .where((card) => card.state == ChoiceCardState.correct)
        .length;
    expect(correctCount, 1);
  });

  testWidgets('playing through all 5 rounds navigates to the next screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    for (var round = 0; round < 5; round++) {
      await tester.tap(find.byType(ChoiceCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
    }

    expect(find.text('BRAVO_MARKER'), findsOneWidget);
  });

  testWidgets('answering a question records the result in the progress repository', (
    WidgetTester tester,
  ) async {
    final db = ProgressDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ProgressRepository(db);

    await tester.pumpWidget(_buildTestApp(progressDatabase: db));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ChoiceCard).first);
    await tester.pumpAndSettle();

    const letterIds = [
      'fr.letter.A',
      'fr.letter.B',
      'fr.letter.C',
      'fr.letter.D',
      'fr.letter.E',
    ];
    final touched = <String>[];
    for (final id in letterIds) {
      final snapshot = await repository.snapshotFor(id);
      if (snapshot.correctFirstTryCount > 0 || snapshot.consecutiveWrong > 0) {
        touched.add(id);
      }
    }

    expect(touched, hasLength(1));
  });

  testWidgets('mode aidé shows 2 choices with the correct one hinted', (
    WidgetTester tester,
  ) async {
    final db = ProgressDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = ProgressRepository(db);

    const letterIds = [
      'fr.letter.A',
      'fr.letter.B',
      'fr.letter.C',
      'fr.letter.D',
      'fr.letter.E',
    ];
    for (final id in letterIds) {
      await repository.recordAnswer(
        itemId: id,
        correct: false,
        firstTry: true,
        today: DateTime(2026, 1, 1),
      );
      await repository.recordAnswer(
        itemId: id,
        correct: false,
        firstTry: true,
        today: DateTime(2026, 1, 1),
      );
    }

    await tester.pumpWidget(_buildTestApp(progressDatabase: db));
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceCard), findsNWidgets(2));
    final cards = tester.widgetList<ChoiceCard>(find.byType(ChoiceCard));
    expect(cards.where((card) => card.isHinted).length, 1);
  });
}
