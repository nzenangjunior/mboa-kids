import 'item_state.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Everything the progression engine needs to know about one item, with no
/// dependency on how it is persisted (CLAUDE.md section 7).
class ItemProgressSnapshot {
  ItemProgressSnapshot({
    required this.itemId,
    this.state = ItemState.aApprendre,
    this.correctFirstTryCount = 0,
    Set<DateTime>? correctFirstTryDays,
    this.consecutiveWrong = 0,
    this.acquiredAt,
    this.reviewStage = 0,
    this.nextDueAt,
  }) : correctFirstTryDays = (correctFirstTryDays ?? const {})
           .map(_dateOnly)
           .toSet();

  final String itemId;
  final ItemState state;
  final int correctFirstTryCount;
  final Set<DateTime> correctFirstTryDays;
  final int consecutiveWrong;
  final DateTime? acquiredAt;

  /// Number of spaced-repetition reviews already completed since
  /// acquisition (0 = just acquired, not reviewed yet).
  final int reviewStage;
  final DateTime? nextDueAt;

  ItemProgressSnapshot copyWith({
    ItemState? state,
    int? correctFirstTryCount,
    Set<DateTime>? correctFirstTryDays,
    int? consecutiveWrong,
    DateTime? acquiredAt,
    int? reviewStage,
    DateTime? nextDueAt,
    bool clearNextDueAt = false,
  }) {
    return ItemProgressSnapshot(
      itemId: itemId,
      state: state ?? this.state,
      correctFirstTryCount: correctFirstTryCount ?? this.correctFirstTryCount,
      correctFirstTryDays: correctFirstTryDays ?? this.correctFirstTryDays,
      consecutiveWrong: consecutiveWrong ?? this.consecutiveWrong,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      reviewStage: reviewStage ?? this.reviewStage,
      nextDueAt: clearNextDueAt ? null : (nextDueAt ?? this.nextDueAt),
    );
  }
}
