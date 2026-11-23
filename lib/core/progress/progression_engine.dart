import 'item_progress_snapshot.dart';
import 'item_state.dart';
import 'spaced_repetition.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Pure progression logic (CLAUDE.md section 7), independently testable:
/// no widget, no database.
///
/// `acquis` requires 3 correct first-try answers spread over at least 2
/// different days. Once an item has been acquired at least once (tracked
/// by [ItemProgressSnapshot.firstAcquiredAt], which is never cleared), it
/// lives on the spaced-repetition schedule: a wrong answer during review
/// demotes it back to `aRevoir` with a review due at J+1. CLAUDE.md rule 5
/// ("pas de punition") is about what the child sees on screen — no sound,
/// no lost screen, no visible setback — not about the internal tracking,
/// which must reflect reality for the parent's follow-up.
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

    if (current.firstAcquiredAt != null) {
      return correct ? _advanceReview(current, day) : _demote(current, day);
    }

    if (!correct) {
      return current.copyWith(consecutiveWrong: current.consecutiveWrong + 1);
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
          firstAcquiredAt: day,
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
        state: ItemState.acquis,
        consecutiveWrong: 0,
        reviewStage: nextStage,
        clearNextDueAt: true,
      );
    }
    return current.copyWith(
      state: ItemState.acquis,
      consecutiveWrong: 0,
      reviewStage: nextStage,
      nextDueAt: day.add(Duration(days: reviewOffsetsInDays[nextStage])),
    );
  }

  ItemProgressSnapshot _demote(ItemProgressSnapshot current, DateTime day) {
    return current.copyWith(
      state: ItemState.aRevoir,
      consecutiveWrong: current.consecutiveWrong + 1,
      reviewStage: 0,
      nextDueAt: day.add(Duration(days: reviewOffsetsInDays[0])),
    );
  }
}
