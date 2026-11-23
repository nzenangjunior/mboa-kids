import 'package:drift/drift.dart';

import 'item_state.dart';

part 'progress_database.g.dart';

/// One row per content item (CLAUDE.md section 7 states and spaced
/// repetition fields). `itemId` is the stable id from the content JSON
/// (e.g. `en.letter.F`), so it is already unique across worlds/modules.
class ItemProgressRows extends Table {
  TextColumn get itemId => text()();
  IntColumn get state => intEnum<ItemState>()();
  IntColumn get correctFirstTryCount => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveWrong => integer().withDefault(const Constant(0))();
  DateTimeColumn get firstAcquiredAt => dateTime().nullable()();
  IntColumn get reviewStage => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextDueAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {itemId};
}

/// Distinct days on which an item was answered correctly on the first try,
/// needed to check the "at least 2 different days" part of `acquis`.
class CorrectFirstTryDays extends Table {
  TextColumn get itemId => text()();
  DateTimeColumn get day => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId, day};
}

/// Every random "fin de partie" sticker ever earned (CLAUDE.md section 8):
/// kept forever, even if the letters played that game are later demoted.
class EarnedStickerRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get stickerId => text()();
  DateTimeColumn get earnedAt => dateTime()();
}

/// Single-row table (id is always 0) for app-wide settings that don't
/// belong to any one content item, such as the celebration intensity
/// (CLAUDE.md section 8). Stored as text rather than an enum column so
/// this schema file doesn't need to depend on `core/rewards`.
class SettingsRows extends Table {
  IntColumn get id => integer()();
  TextColumn get intensity => text().withDefault(const Constant('normal'))();

  /// Opaque cursor (an "id#occurrence" key, see `tracing_queue.dart`) for
  /// the last tracing queue item completed, across all sessions (CLAUDE.md
  /// section 10: at most 5 traces per session, resuming where it left off
  /// rather than restarting from the first name every time). An occurrence
  /// number is needed, not just the id, because a repeated letter in the
  /// name (e.g. the two E's in ESTRELLA) would otherwise be ambiguous.
  TextColumn get tracingQueueCursor => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Days on which an item was successfully traced with the guide
/// (CLAUDE.md section 10): the "sans guide" pass is only offered once one
/// of these days is strictly before today, never in the same session.
class TracingGuidedSuccessDays extends Table {
  TextColumn get itemId => text()();
  DateTimeColumn get day => dateTime()();

  @override
  Set<Column> get primaryKey => {itemId, day};
}

/// This schema has no platform-specific connection logic of its own: how to
/// actually open it (native SQLite file on Android/desktop, or SQLite
/// compiled to WebAssembly on the web dev preview) lives in
/// `progress_repository_io.dart` / `progress_repository_web.dart`, so that
/// this file never pulls in `dart:io` or `dart:ffi` and stays safe to
/// import from web-compiled code.
@DriftDatabase(
  tables: [
    ItemProgressRows,
    CorrectFirstTryDays,
    EarnedStickerRows,
    SettingsRows,
    TracingGuidedSuccessDays,
  ],
)
class ProgressDatabase extends _$ProgressDatabase {
  ProgressDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(tracingGuidedSuccessDays);
        await m.addColumn(settingsRows, settingsRows.tracingQueueCursor);
      }
    },
  );
}
