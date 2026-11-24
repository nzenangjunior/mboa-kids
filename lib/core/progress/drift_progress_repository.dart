// The public constructor parameter is named `engine` (readable call sites),
// while the field is private `_engine`; an initializing formal would force
// the parameter itself to be named `_engine`.
// ignore_for_file: prefer_initializing_formals
import 'package:drift/drift.dart';

import '../rewards/intensity_level.dart';
import 'item_progress_snapshot.dart';
import 'item_state.dart';
import 'progress_database.dart';
import 'progress_repository.dart';
import 'progression_engine.dart';

/// Loads and saves [ItemProgressSnapshot]s in [ProgressDatabase] (real
/// SQLite via drift), applying [ProgressionEngine] rules when an answer
/// comes in. This is the only place that knows how the pure progression
/// logic maps onto SQL rows.
class DriftProgressRepository implements ProgressRepository {
  DriftProgressRepository(
    this._db, {
    ProgressionEngine engine = const ProgressionEngine(),
  }) : _engine = engine;

  final ProgressDatabase _db;
  final ProgressionEngine _engine;

  @override
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

  @override
  Future<void> seed(String itemId, ItemState state) {
    return _db
        .into(_db.itemProgressRows)
        .insertOnConflictUpdate(
          ItemProgressRowsCompanion.insert(itemId: itemId, state: state),
        );
  }

  @override
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

  @override
  Future<Map<String, ItemState>> statesFor(List<String> itemIds) async {
    final rows = await (_db.select(
      _db.itemProgressRows,
    )..where((t) => t.itemId.isIn(itemIds))).get();
    return {for (final row in rows) row.itemId: row.state};
  }

  @override
  Future<void> recordStickerEarned(String stickerId, DateTime earnedAt) {
    return _db
        .into(_db.earnedStickerRows)
        .insert(
          EarnedStickerRowsCompanion.insert(
            stickerId: stickerId,
            earnedAt: earnedAt,
          ),
        );
  }

  @override
  Future<Set<String>> earnedStickerIds() async {
    final rows = await _db.select(_db.earnedStickerRows).get();
    return rows.map((r) => r.stickerId).toSet();
  }

  @override
  Future<IntensityLevel> intensity() async {
    final row = await (_db.select(
      _db.settingsRows,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    if (row == null) return IntensityLevel.normal;
    return IntensityLevel.values.firstWhere(
      (level) => level.name == row.intensity,
      orElse: () => IntensityLevel.normal,
    );
  }

  @override
  Future<void> setIntensity(IntensityLevel level) {
    return _db
        .into(_db.settingsRows)
        .insertOnConflictUpdate(
          SettingsRowsCompanion.insert(id: const Value(0), intensity: Value(level.name)),
        );
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Future<bool> hasTracingGuidedSuccessBefore(String itemId, DateTime day) async {
    final cutoff = _dateOnly(day);
    final rows = await (_db.select(_db.tracingGuidedSuccessDays)
          ..where((t) => t.itemId.equals(itemId) & t.day.isSmallerThanValue(cutoff)))
        .get();
    return rows.isNotEmpty;
  }

  @override
  Future<void> recordTracingGuidedSuccess(String itemId, DateTime day) {
    return _db
        .into(_db.tracingGuidedSuccessDays)
        .insertOnConflictUpdate(
          TracingGuidedSuccessDaysCompanion.insert(itemId: itemId, day: _dateOnly(day)),
        );
  }

  @override
  Future<String?> tracingQueueCursor() async {
    final row = await (_db.select(
      _db.settingsRows,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    return row?.tracingQueueCursor;
  }

  @override
  Future<void> setTracingQueueCursor(String cursor) {
    return _db
        .into(_db.settingsRows)
        .insertOnConflictUpdate(
          SettingsRowsCompanion.insert(
            id: const Value(0),
            tracingQueueCursor: Value(cursor),
          ),
        );
  }

  @override
  Future<String?> lastWorld() async {
    final row = await (_db.select(
      _db.settingsRows,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    return row?.world;
  }

  @override
  Future<void> setLastWorld(String world) {
    return _db
        .into(_db.settingsRows)
        .insertOnConflictUpdate(
          SettingsRowsCompanion.insert(id: const Value(0), world: Value(world)),
        );
  }

  @override
  Future<int> bestStarsFor(String levelId) async {
    final row = await (_db.select(
      _db.levelBestStarRows,
    )..where((t) => t.levelId.equals(levelId))).getSingleOrNull();
    return row?.bestStars ?? 0;
  }

  @override
  Future<void> recordLevelStars(String levelId, int stars) async {
    final current = await bestStarsFor(levelId);
    if (stars <= current) return;
    await _db
        .into(_db.levelBestStarRows)
        .insertOnConflictUpdate(
          LevelBestStarRowsCompanion.insert(levelId: levelId, bestStars: stars),
        );
  }

  @override
  Future<int> albumLastSeenCount() async {
    final row = await (_db.select(
      _db.settingsRows,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    return row?.albumLastSeenCount ?? 0;
  }

  @override
  Future<void> setAlbumLastSeenCount(int count) {
    return _db
        .into(_db.settingsRows)
        .insertOnConflictUpdate(
          SettingsRowsCompanion.insert(id: const Value(0), albumLastSeenCount: Value(count)),
        );
  }

  @override
  Future<Map<String, (double, double)>> stickerPositions() async {
    final rows = await _db.select(_db.stickerPositionRows).get();
    return {for (final row in rows) row.stickerId: (row.dx, row.dy)};
  }

  @override
  Future<void> setStickerPosition(String stickerId, double dx, double dy) {
    return _db
        .into(_db.stickerPositionRows)
        .insertOnConflictUpdate(
          StickerPositionRowsCompanion.insert(stickerId: stickerId, dx: dx, dy: dy),
        );
  }

  @override
  Future<bool> hasShownPlayHint() async {
    final row = await (_db.select(
      _db.settingsRows,
    )..where((t) => t.id.equals(0))).getSingleOrNull();
    return row?.hasShownPlayHint ?? false;
  }

  @override
  Future<void> setHasShownPlayHint(bool value) {
    return _db
        .into(_db.settingsRows)
        .insertOnConflictUpdate(
          SettingsRowsCompanion.insert(id: const Value(0), hasShownPlayHint: Value(value)),
        );
  }

  @override
  Future<void> dispose() => _db.close();
}
