import 'dart:async';
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
import 'package:mboa_kids/core/progress/drift_progress_repository.dart';
import 'package:mboa_kids/core/progress/progress_database.dart';
import 'package:mboa_kids/core/progress/progress_repository.dart';
import 'package:mboa_kids/features/alphabet/alphabet_game_screen.dart';
import 'package:mboa_kids/features/rewards/bravo_result.dart';
import 'package:mboa_kids/shared/widgets/choice_card.dart';
import 'package:mboa_kids/shared/widgets/mascot.dart';

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

/// Records every call (in order) and takes a non-trivial, configurable
/// time to "speak" a prompt or item — long enough that a test can tap
/// mid-speech and observe whether that tap was ignored (CLAUDE.md section
/// 10: "toucher le perroquet pendant qu'il parle : ignoré").
class _RecordingAudioService implements AudioService {
  _RecordingAudioService({this.speakDelay = const Duration(milliseconds: 200)});

  final List<String> calls = [];
  final Duration speakDelay;

  @override
  Future<void> playItem(String itemId) async {
    calls.add('item:$itemId');
    await Future<void>.delayed(speakDelay);
  }

  @override
  Future<void> playPrompt(String key) async {
    calls.add('prompt:$key');
    await Future<void>.delayed(speakDelay);
  }

  @override
  Future<void> playSfx(String name) async {
    calls.add('sfx:$name');
  }

  @override
  Future<void> playPraise() async {
    calls.add('praise');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }
}

/// Simulates a voice that never reports completion (CLAUDE.md section 13:
/// the web `speechSynthesis` API can leave an utterance's completion event
/// unfired after an interruption). Every call here returns a `Future` that
/// resolves only if [stop] is called, so a test can check that the game
/// stays playable regardless.
class _NeverCompletingAudioService implements AudioService {
  final List<Completer<void>> _pending = [];

  Future<void> _hang() {
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  @override
  Future<void> playItem(String itemId) => _hang();

  @override
  Future<void> playPrompt(String key) => _hang();

  @override
  Future<void> playSfx(String name) => _hang();

  @override
  Future<void> playPraise() => _hang();

  @override
  Future<void> stop() async {
    for (final completer in _pending) {
      if (!completer.isCompleted) completer.complete();
    }
    _pending.clear();
  }
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

/// A bounded stand-in for `pumpAndSettle()`: the mascot's idle animation
/// (`Mascot`, CLAUDE.md section 10) runs continuously, like the Bravo
/// screen's confetti, so a real `pumpAndSettle()` never finds a moment
/// with no frame scheduled and times out. This instead pumps a fixed,
/// generous number of frames — enough for any pending async work
/// (provider resolution, database reads) to settle, without waiting on
/// the animation itself.
Future<void> _pumpUntilIdle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Widget _buildTestApp({
  ProgressRepository? progressRepository,
  AudioService? audioService,
  int? packNumber,
  void Function(BravoResult result)? onFinished,
}) {
  return ProviderScope(
    overrides: [
      worldProvider.overrideWith((ref) => 'fr'),
      contentLoaderProvider.overrideWithValue(
        ContentLoader(
          _FakeAssetBundle({'assets/content/fr/alphabet.json': _alphabetJson}),
        ),
      ),
      audioServiceProvider(
        'fr',
      ).overrideWith((ref) async => audioService ?? _FakeAudioService()),
      progressRepositoryProvider.overrideWithValue(
        progressRepository ??
            DriftProgressRepository(ProgressDatabase(NativeDatabase.memory())),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                AlphabetGameScreen(packNumber: packNumber, onFinished: onFinished),
          ),
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
    await _pumpUntilIdle(tester);

    expect(find.byType(ChoiceCard), findsNWidgets(3));
  });

  testWidgets('tapping a choice reveals exactly one correct answer, with no Continuer button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await _pumpUntilIdle(tester);

    await tester.tap(find.byType(ChoiceCard).first);
    await _pumpUntilIdle(tester);

    expect(find.text('Continuer'), findsNothing);

    final cards = tester.widgetList<ChoiceCard>(find.byType(ChoiceCard));
    final correctCount = cards
        .where((card) => card.state == ChoiceCardState.correct)
        .length;
    expect(correctCount, 1);
  });

  testWidgets('a wrong answer brings back the exact same question', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await _pumpUntilIdle(tester);

    final before = tester
        .widgetList<ChoiceCard>(find.byType(ChoiceCard))
        .map((c) => c.label)
        .toSet();

    await tester.tap(find.byType(ChoiceCard).first);
    await _pumpUntilIdle(tester);

    final tappedWasWrong = tester
        .widgetList<ChoiceCard>(find.byType(ChoiceCard))
        .any((c) => c.state == ChoiceCardState.incorrect);
    if (!tappedWasWrong) {
      // Tapped the correct choice by chance; nothing to retry here.
      return;
    }

    await tester.pump(const Duration(milliseconds: 1700));
    await _pumpUntilIdle(tester);

    final after = tester
        .widgetList<ChoiceCard>(find.byType(ChoiceCard))
        .map((c) => c.label)
        .toSet();
    expect(after, before);
  });

  testWidgets('playing through the whole game navigates to the next screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTestApp());
    await _pumpUntilIdle(tester);

    for (var attempt = 0; attempt < 40; attempt++) {
      if (find.text('BRAVO_MARKER').evaluate().isNotEmpty) break;
      final cards = find.byType(ChoiceCard);
      final count = tester.widgetList<ChoiceCard>(cards).length;
      await tester.tap(cards.at(attempt % count));
      await tester.pump(const Duration(milliseconds: 1700));
      await _pumpUntilIdle(tester);
    }

    expect(find.text('BRAVO_MARKER'), findsOneWidget);
  });

  testWidgets('answering a question records the result in the progress repository', (
    WidgetTester tester,
  ) async {
    final db = ProgressDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftProgressRepository(db);

    await tester.pumpWidget(_buildTestApp(progressRepository: repository));
    await _pumpUntilIdle(tester);

    await tester.tap(find.byType(ChoiceCard).first);
    await _pumpUntilIdle(tester);

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
    final db = ProgressDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftProgressRepository(db);

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

    await tester.pumpWidget(_buildTestApp(progressRepository: repository));
    await _pumpUntilIdle(tester);

    expect(find.byType(ChoiceCard), findsNWidgets(2));
    final cards = tester.widgetList<ChoiceCard>(find.byType(ChoiceCard));
    expect(cards.where((card) => card.isHinted).length, 1);
  });

  testWidgets(
    'the game stays playable when the voice never reports completion',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(audioService: _NeverCompletingAudioService()),
      );
      await _pumpUntilIdle(tester);

      // Every tap below waits past the feedback timer (1700ms > the 1500ms
      // auto-advance and the 1000ms wrong-answer highlight), so each one
      // must either advance to a new round or retry the same one — never
      // sit frozen waiting on audio that will never resolve.
      for (var attempt = 0; attempt < 40; attempt++) {
        if (find.text('BRAVO_MARKER').evaluate().isNotEmpty) break;
        final cards = find.byType(ChoiceCard);
        final widgets = tester.widgetList<ChoiceCard>(cards).toList();
        // Mirrors a real child tapping the glowing hint once mode aidé
        // kicks in, instead of cycling blind: with only 2 choices left,
        // index-cycling can unluckily miss the same one for many rounds in
        // a row, which is noise this test (about staying playable, not
        // about guessing odds) doesn't need.
        final hintedIndex = widgets.indexWhere((c) => c.isHinted);
        final tapIndex = hintedIndex >= 0 ? hintedIndex : attempt % widgets.length;
        await tester.tap(cards.at(tapIndex));
        await tester.pump(const Duration(milliseconds: 1700));
        await _pumpUntilIdle(tester);

        final stillHasChoices = find.byType(ChoiceCard).evaluate().isNotEmpty;
        final reachedBravo = find.text('BRAVO_MARKER').evaluate().isNotEmpty;
        expect(
          stillHasChoices || reachedBravo,
          isTrue,
          reason: 'round $attempt: game is stuck with no tappable choices',
        );
      }

      expect(find.text('BRAVO_MARKER'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a choice several times fast while it is still highlighted does not break the round',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(audioService: _NeverCompletingAudioService()),
      );
      await _pumpUntilIdle(tester);

      final firstChoice = find.byType(ChoiceCard).first;
      for (var i = 0; i < 5; i++) {
        await tester.tap(firstChoice, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pump(const Duration(milliseconds: 1700));
      await _pumpUntilIdle(tester);

      expect(find.byType(ChoiceCard), findsWidgets);
    },
  );

  group('level path (CLAUDE.md section 10: 1 niveau = 1 paquet)', () {
    testWidgets('packNumber targets only that pack\'s letters, round after round', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(packNumber: 1));
      await _pumpUntilIdle(tester);

      for (var round = 0; round < 5; round++) {
        await tester.tap(find.byType(ChoiceCard).first);
        await tester.pump();
        final target = tester
            .widgetList<ChoiceCard>(find.byType(ChoiceCard))
            .firstWhere((card) => card.state == ChoiceCardState.correct);
        expect(['A', 'B', 'C'], contains(target.label));

        await tester.pump(const Duration(milliseconds: 1700));
        await _pumpUntilIdle(tester);
      }
    });

    testWidgets('onFinished is called instead of navigating to /bravo directly', (
      WidgetTester tester,
    ) async {
      BravoResult? result;
      await tester.pumpWidget(_buildTestApp(onFinished: (r) => result = r));
      await _pumpUntilIdle(tester);

      for (var attempt = 0; attempt < 40; attempt++) {
        if (result != null) break;
        final cards = find.byType(ChoiceCard);
        final count = tester.widgetList<ChoiceCard>(cards).length;
        await tester.tap(cards.at(attempt % count));
        await tester.pump(const Duration(milliseconds: 1700));
        await _pumpUntilIdle(tester);
      }

      expect(result, isNotNull);
      expect(
        find.text('BRAVO_MARKER'),
        findsNothing,
        reason: 'onFinished replaces the default navigation to /bravo',
      );
    });

    testWidgets('finishing a pack-scoped game records that level\'s best stars', (
      WidgetTester tester,
    ) async {
      final db = ProgressDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = DriftProgressRepository(db);

      await tester.pumpWidget(
        _buildTestApp(progressRepository: repository, packNumber: 1),
      );
      await _pumpUntilIdle(tester);

      for (var attempt = 0; attempt < 40; attempt++) {
        if (find.text('BRAVO_MARKER').evaluate().isNotEmpty) break;
        final cards = find.byType(ChoiceCard);
        final count = tester.widgetList<ChoiceCard>(cards).length;
        await tester.tap(cards.at(attempt % count));
        await tester.pump(const Duration(milliseconds: 1700));
        await _pumpUntilIdle(tester);
      }

      expect(find.text('BRAVO_MARKER'), findsOneWidget);
      final best = await repository.bestStarsFor('fr.alphabet.pack1');
      expect(best, greaterThanOrEqualTo(1));
    });
  });

  group('one instruction at a time (CLAUDE.md section 10)', () {
    testWidgets(
      'tapping the mascot repeatedly while it speaks never queues a second instruction, '
      'and a wrong answer only re-speaks it once on retry',
      (WidgetTester tester) async {
        final audio = _RecordingAudioService();
        await tester.pumpWidget(_buildTestApp(audioService: audio));

        for (var i = 0; i < 30 && find.byType(ChoiceCard).evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(find.byType(ChoiceCard), findsWidgets);
        expect(
          audio.calls.where((c) => c.startsWith('prompt:find_the_letter')).length,
          1,
          reason: 'the question appearing speaks its instruction exactly once',
        );

        // 5 rapid taps on the mascot, all while that first instruction is
        // still "being spoken" (the fake's 200ms delay hasn't elapsed).
        for (var i = 0; i < 5; i++) {
          await tester.tap(find.byType(Mascot));
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(
          audio.calls.where((c) => c.startsWith('prompt:find_the_letter')).length,
          1,
          reason: 'every tap landed mid-speech and must have been ignored',
        );

        // Let the instruction actually finish (playPrompt then playItem,
        // 200ms each), then a real replay works.
        await tester.pump(const Duration(milliseconds: 450));
        await tester.tap(find.byType(Mascot));
        await tester.pump(const Duration(milliseconds: 10));
        expect(audio.calls.where((c) => c.startsWith('prompt:find_the_letter')).length, 2);
        await tester.pump(const Duration(milliseconds: 450));

        // Answer whichever choice comes first — correct or wrong, the
        // same invariant applies either way (retry on wrong, or the next
        // round on correct): the next question speaks its instruction
        // exactly once, never twice.
        await tester.tap(find.byType(ChoiceCard).first);
        await tester.pump(const Duration(milliseconds: 50));

        final afterAnswerTap = audio.calls.length;
        // Covers the longer of the two delays (1.5s on correct, 1s on
        // wrong) plus the next instruction's own playPrompt+playItem
        // (200ms each) — pumped in small steps (not one big jump) so any
        // async work in between (e.g. _prepareRound's own DB read) gets
        // a chance to resolve, same as elsewhere in this file.
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        final spokenAfterAnswering = audio.calls
            .sublist(afterAnswerTap)
            .where((c) => c.startsWith('prompt:find_the_letter'))
            .length;
        expect(
          spokenAfterAnswering,
          1,
          reason:
              'the next question (retry on wrong, or the next round on correct) must '
              'speak its instruction exactly once',
        );
      },
    );

    testWidgets(
      'an unanswered question repeats its instruction once after 6s, then reveals '
      'the answer without saying it after 6s more',
      (WidgetTester tester) async {
        final audio = _RecordingAudioService(speakDelay: Duration.zero);
        await tester.pumpWidget(_buildTestApp(audioService: audio));

        for (var i = 0; i < 30 && find.byType(ChoiceCard).evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(
          audio.calls.where((c) => c.startsWith('prompt:find_the_letter')).length,
          1,
        );

        await tester.pump(const Duration(seconds: 6));
        expect(
          audio.calls.where((c) => c.startsWith('prompt:find_the_letter')).length,
          2,
          reason: '6 unanswered seconds repeats the instruction exactly once',
        );
        expect(
          tester.widgetList<ChoiceCard>(find.byType(ChoiceCard)).any((c) => c.isHinted),
          isFalse,
          reason: 'the first timeout only repeats the instruction, it does not reveal anything',
        );

        await tester.pump(const Duration(seconds: 6));
        expect(
          audio.calls.where((c) => c.startsWith('prompt:find_the_letter')).length,
          2,
          reason: 'the second timeout reveals the answer silently, it must not speak again',
        );
        expect(
          tester.widgetList<ChoiceCard>(find.byType(ChoiceCard)).where((c) => c.isHinted).length,
          1,
          reason: 'exactly the correct choice is now shown via a hint',
        );
      },
    );
  });
}
