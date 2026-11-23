// The public constructor parameter is named `engine` (readable call sites),
// while the field is private `_engine`; an initializing formal would force
// the parameter itself to be named `_engine`.
// ignore_for_file: prefer_initializing_formals
import 'package:drift/drift.dart';

import 'item_progress_snapshot.dart';
import 'item_state.dart';
import 'progress_database.dart';
import 'progression_engine.dart';

/// Loads and saves [ItemProgressSnapshot]s in [ProgressDatabase], applying
/// [ProgressionEngine] rules when an answer comes in. This is the only
/// place that knows how the pure progression logic maps onto SQL rows.
class ProgressRepository {
  ProgressRepository(
    this._db, {
    ProgressionEngine engine = const ProgressionEngine(),
  }) : _engine = engine;

  final ProgressDatabase _db;
  final ProgressionEngine _engine;

  Future<ItemProgressSnapshot> snapshotFor(String itemId) async {
    final row = await (_db.select(
      _db.itemProgressRows,
    )..where((t) => t.itemId.equals(itemId))).getSingleOrNull();
    final days = await _correctFirstTryDays(itemId);

    if (row == null) {
      return ItemProgressSnapshot(itemId: itemId, correctFirstTryDays: days);
    }

    return ItemProgressSnapshot(
      itemId: itemId,
      state: row.state,
      correctFirstTryCount: row.correctFirstTryCount,
      correctFirstTryDays: days,
      consecutiveWrong: row.consecutiveWrong,
      firstAcquiredAt: row.firstAcquiredAt,
      reviewStage: row.reviewStage,
      nextDueAt: row.nextDueAt,
    );
  }

  Future<Set<DateTime>> _correctFirstTryDays(String itemId) async {
    final rows = await (_db.select(
      _db.correctFirstTryDays,
    )..where((t) => t.itemId.equals(itemId))).get();
    return rows.map((r) => r.day).toSet();
  }

  /// Seeds an item directly into a given state, used for the English start
  /// set (A-E and 1-10 begin in `aRevoir`, CLAUDE.md section 7).
  Future<void> seed(String itemId, ItemState state) {
    return _db
        .into(_db.itemProgressRows)
        .insertOnConflictUpdate(
          ItemProgressRowsCompanion.insert(itemId: itemId, state: state),
        );
  }

  Future<ItemProgressSnapshot> recordAnswer({
    required String itemId,
    required bool correct,
    required bool firstTry,
    required DateTime today,
  }) async {
    final current = await snapshotFor(itemId);
    final next = _engine.recordAnswer(
      current: current,
      correct: correct,
      firstTry: firstTry,
      today: today,
    );
    await _save(next);
    return next;
  }

  Future<void> _save(ItemProgressSnapshot snapshot) async {
    await _db
        .into(_db.itemProgressRows)
        .insertOnConflictUpdate(
          ItemProgressRowsCompanion.insert(
            itemId: snapshot.itemId,
            state: snapshot.state,
            correctFirstTryCount: Value(snapshot.correctFirstTryCount),
            consecutiveWrong: Value(snapshot.consecutiveWrong),
            firstAcquiredAt: Value(snapshot.firstAcquiredAt),
            reviewStage: Value(snapshot.reviewStage),
            nextDueAt: Value(snapshot.nextDueAt),
          ),
        );

    for (final day in snapshot.correctFirstTryDays) {
      await _db
          .into(_db.correctFirstTryDays)
          .insertOnConflictUpdate(
            CorrectFirstTryDaysCompanion.insert(
              itemId: snapshot.itemId,
              day: day,
            ),
          );
    }
  }

  Future<Map<String, ItemState>> statesFor(List<String> itemIds) async {
    final rows = await (_db.select(
      _db.itemProgressRows,
    )..where((t) => t.itemId.isIn(itemIds))).get();
    return {for (final row in rows) row.itemId: row.state};
  }
}
