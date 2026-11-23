import 'item_progress_snapshot.dart';
import 'item_state.dart';
import 'spaced_repetition.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Pure progression logic (CLAUDE.md section 7), independently testable:
/// no widget, no database.
///
/// `acquis` requires 3 correct first-try answers spread over at least 2
/// different days. Once acquired, an item is never demoted by a wrong
/// answer during review: CLAUDE.md rule 5 forbids punishing mistakes, and
/// a status lost over a slip would read as a punishment. A wrong review
/// answer simply leaves the item due again, unchanged.
class ProgressionEngine {
  const ProgressionEngine({
    this.acquisitionThreshold = 3,
    this.acquisitionMinDistinctDays = 2,
    this.aidedModeAfterConsecutiveWrong = 2,
    this.reviewOffsetsInDays = spacedRepetitionOffsetsInDays,
  });

  final int acquisitionThreshold;
  final int acquisitionMinDistinctDays;
  final int aidedModeAfterConsecutiveWrong;
  final List<int> reviewOffsetsInDays;

  /// Whether this item should be presented in "mode aidé" (2 choices
  /// instead of 3, correct one highlighted) right now.
  bool shouldUseAidedMode(ItemProgressSnapshot snapshot) {
    return snapshot.consecutiveWrong >= aidedModeAfterConsecutiveWrong;
  }

  /// Returns the updated snapshot after one answer to this item.
  ItemProgressSnapshot recordAnswer({
    required ItemProgressSnapshot current,
    required bool correct,
    required bool firstTry,
    required DateTime today,
  }) {
    final day = _dateOnly(today);

    if (!correct) {
      return current.copyWith(consecutiveWrong: current.consecutiveWrong + 1);
    }

    if (current.state == ItemState.acquis) {
      return _advanceReview(current, day);
    }

    var next = current.copyWith(consecutiveWrong: 0);

    if (firstTry) {
      final days = {...current.correctFirstTryDays, day};
      next = next.copyWith(
        correctFirstTryCount: current.correctFirstTryCount + 1,
        correctFirstTryDays: days,
      );

      if (next.correctFirstTryCount >= acquisitionThreshold &&
          next.correctFirstTryDays.length >= acquisitionMinDistinctDays) {
        return next.copyWith(
          state: ItemState.acquis,
          acquiredAt: day,
          reviewStage: 0,
          nextDueAt: day.add(Duration(days: reviewOffsetsInDays[0])),
        );
      }
    }

    if (next.state == ItemState.aApprendre) {
      next = next.copyWith(state: ItemState.enCours);
    }

    return next;
  }

  ItemProgressSnapshot _advanceReview(ItemProgressSnapshot current, DateTime day) {
    final nextStage = current.reviewStage + 1;
    if (nextStage >= reviewOffsetsInDays.length) {
      return current.copyWith(
        consecutiveWrong: 0,
        reviewStage: nextStage,
        clearNextDueAt: true,
      );
    }
    final anchor = current.acquiredAt ?? day;
    return current.copyWith(
      consecutiveWrong: 0,
      reviewStage: nextStage,
      nextDueAt: anchor.add(Duration(days: reviewOffsetsInDays[nextStage])),
    );
  }
}
