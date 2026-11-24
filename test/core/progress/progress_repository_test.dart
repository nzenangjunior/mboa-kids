import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/progress/drift_progress_repository.dart';
import 'package:mboa_kids/core/progress/item_state.dart';
import 'package:mboa_kids/core/progress/progress_database.dart';
import 'package:mboa_kids/core/progress/progress_repository.dart';

void main() {
  late ProgressDatabase db;
  late ProgressRepository repository;

  setUp(() {
    db = ProgressDatabase(NativeDatabase.memory());
    repository = DriftProgressRepository(db);
  });

  tearDown(() => db.close());

  test('an item with no history starts as aApprendre', () async {
    final snapshot = await repository.snapshotFor('en.letter.F');

    expect(snapshot.state, ItemState.aApprendre);
    expect(snapshot.correctFirstTryCount, 0);
  });

  test('seed sets the starting state for English start items', () async {
    await repository.seed('en.letter.A', ItemState.aRevoir);

    final snapshot = await repository.snapshotFor('en.letter.A');
    expect(snapshot.state, ItemState.aRevoir);
  });

  test('recordAnswer persists progress across reads', () async {
    final day1 = DateTime(2026, 1, 1);
    final day2 = DateTime(2026, 1, 2);

    await repository.recordAnswer(
      itemId: 'en.letter.F',
      correct: true,
      firstTry: true,
      today: day1,
    );
    await repository.recordAnswer(
      itemId: 'en.letter.F',
      correct: true,
      firstTry: true,
      today: day1,
    );
    final third = await repository.recordAnswer(
      itemId: 'en.letter.F',
      correct: true,
      firstTry: true,
      today: day2,
    );

    expect(third.state, ItemState.acquis);

    final reloaded = await repository.snapshotFor('en.letter.F');
    expect(reloaded.state, ItemState.acquis);
    expect(reloaded.correctFirstTryCount, 3);
    expect(reloaded.correctFirstTryDays, {day1, day2});
    expect(reloaded.firstAcquiredAt, day2);
  });

  test('statesFor returns the current state of several items at once', () async {
    await repository.seed('en.letter.A', ItemState.aRevoir);
    await repository.seed('en.letter.B', ItemState.acquis);

    final states = await repository.statesFor(['en.letter.A', 'en.letter.B', 'en.letter.C']);

    expect(states['en.letter.A'], ItemState.aRevoir);
    expect(states['en.letter.B'], ItemState.acquis);
    expect(states.containsKey('en.letter.C'), isFalse);
  });

  group('lastWorld', () {
    test('is null until a world is chosen', () async {
      expect(await repository.lastWorld(), isNull);
    });

    test('persists the chosen world across reads', () async {
      await repository.setLastWorld('en');

      expect(await repository.lastWorld(), 'en');
    });
  });

  group('level best stars', () {
    test('a never-played level has 0 best stars', () async {
      expect(await repository.bestStarsFor('fr.alphabet.pack1'), 0);
    });

    test('keeps the higher of two recorded scores', () async {
      await repository.recordLevelStars('fr.alphabet.pack1', 2);
      await repository.recordLevelStars('fr.alphabet.pack1', 1);

      expect(await repository.bestStarsFor('fr.alphabet.pack1'), 2);
    });

    test('a higher score later replaces a lower best', () async {
      await repository.recordLevelStars('fr.alphabet.pack1', 1);
      await repository.recordLevelStars('fr.alphabet.pack1', 3);

      expect(await repository.bestStarsFor('fr.alphabet.pack1'), 3);
    });

    test('levels are tracked independently', () async {
      await repository.recordLevelStars('fr.alphabet.pack1', 3);

      expect(await repository.bestStarsFor('fr.alphabet.pack2'), 0);
    });
  });
}
