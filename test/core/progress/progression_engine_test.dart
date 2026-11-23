import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/progress/item_progress_snapshot.dart';
import 'package:mboa_kids/core/progress/item_state.dart';
import 'package:mboa_kids/core/progress/progression_engine.dart';

void main() {
  final engine = ProgressionEngine();
  final day1 = DateTime(2026, 1, 1);
  final day2 = DateTime(2026, 1, 2);

  group('learning a new item', () {
    test('first correct first-try answer moves aApprendre to enCours', () {
      final snapshot = ItemProgressSnapshot(itemId: 'en.letter.F');

      final next = engine.recordAnswer(
        current: snapshot,
        correct: true,
        firstTry: true,
        today: day1,
      );

      expect(next.state, ItemState.enCours);
      expect(next.correctFirstTryCount, 1);
      expect(next.correctFirstTryDays, {day1});
    });

    test('a correct answer that is not first try still promotes aApprendre', () {
      final snapshot = ItemProgressSnapshot(itemId: 'en.letter.F');

      final next = engine.recordAnswer(
        current: snapshot,
        correct: true,
        firstTry: false,
        today: day1,
      );

      expect(next.state, ItemState.enCours);
      expect(next.correctFirstTryCount, 0);
    });

    test('3 correct first-try answers on the same day are not enough', () {
      var snapshot = ItemProgressSnapshot(itemId: 'en.letter.F');
      for (var i = 0; i < 3; i++) {
        snapshot = engine.recordAnswer(
          current: snapshot,
          correct: true,
          firstTry: true,
          today: day1,
        );
      }

      expect(snapshot.state, ItemState.enCours);
      expect(snapshot.correctFirstTryCount, 3);
    });

    test('3 correct first-try answers across 2 distinct days reach acquis', () {
      var snapshot = ItemProgressSnapshot(itemId: 'en.letter.F');
      snapshot = engine.recordAnswer(
        current: snapshot,
        correct: true,
        firstTry: true,
        today: day1,
      );
      snapshot = engine.recordAnswer(
        current: snapshot,
        correct: true,
        firstTry: true,
        today: day1,
      );
      snapshot = engine.recordAnswer(
        current: snapshot,
        correct: true,
        firstTry: true,
        today: day2,
      );

      expect(snapshot.state, ItemState.acquis);
      expect(snapshot.acquiredAt, day2);
      expect(snapshot.reviewStage, 0);
      expect(snapshot.nextDueAt, day2.add(const Duration(days: 1)));
    });
  });

  group('mode aidé', () {
    test('is off below the consecutive-wrong threshold', () {
      final snapshot = ItemProgressSnapshot(
        itemId: 'en.letter.F',
        consecutiveWrong: 1,
      );

      expect(engine.shouldUseAidedMode(snapshot), isFalse);
    });

    test('turns on after 2 consecutive wrong answers', () {
      var snapshot = ItemProgressSnapshot(itemId: 'en.letter.F');
      snapshot = engine.recordAnswer(
        current: snapshot,
        correct: false,
        firstTry: true,
        today: day1,
      );
      snapshot = engine.recordAnswer(
        current: snapshot,
        correct: false,
        firstTry: true,
        today: day1,
      );

      expect(engine.shouldUseAidedMode(snapshot), isTrue);
    });

    test('a correct answer resets the consecutive-wrong streak', () {
      var snapshot = ItemProgressSnapshot(
        itemId: 'en.letter.F',
        consecutiveWrong: 2,
      );

      snapshot = engine.recordAnswer(
        current: snapshot,
        correct: true,
        firstTry: true,
        today: day1,
      );

      expect(snapshot.consecutiveWrong, 0);
      expect(engine.shouldUseAidedMode(snapshot), isFalse);
    });
  });

  group('spaced repetition review', () {
    test('a correct review advances J+1 to J+3', () {
      final acquired = ItemProgressSnapshot(
        itemId: 'en.letter.A',
        state: ItemState.acquis,
        acquiredAt: day1,
        reviewStage: 0,
        nextDueAt: day1.add(const Duration(days: 1)),
      );

      final next = engine.recordAnswer(
        current: acquired,
        correct: true,
        firstTry: true,
        today: day1.add(const Duration(days: 1)),
      );

      expect(next.state, ItemState.acquis);
      expect(next.reviewStage, 1);
      expect(next.nextDueAt, day1.add(const Duration(days: 3)));
    });

    test('completing the J+7 review clears the due date', () {
      final acquired = ItemProgressSnapshot(
        itemId: 'en.letter.A',
        state: ItemState.acquis,
        acquiredAt: day1,
        reviewStage: 2,
        nextDueAt: day1.add(const Duration(days: 7)),
      );

      final next = engine.recordAnswer(
        current: acquired,
        correct: true,
        firstTry: true,
        today: day1.add(const Duration(days: 7)),
      );

      expect(next.reviewStage, 3);
      expect(next.nextDueAt, isNull);
    });

    test('a wrong review answer never demotes an acquired item', () {
      final acquired = ItemProgressSnapshot(
        itemId: 'en.letter.A',
        state: ItemState.acquis,
        acquiredAt: day1,
        reviewStage: 0,
        nextDueAt: day1.add(const Duration(days: 1)),
      );

      final next = engine.recordAnswer(
        current: acquired,
        correct: false,
        firstTry: true,
        today: day1.add(const Duration(days: 1)),
      );

      expect(next.state, ItemState.acquis);
      expect(next.reviewStage, 0);
      expect(next.nextDueAt, acquired.nextDueAt);
    });
  });
}
