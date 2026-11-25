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

  /// The last chosen world ('fr'/'en'), remembered across launches
  /// (CLAUDE.md section 10: "le monde choisi est mémorisé"). Null means
  /// never chosen yet — the app falls back to its own default then.
  TextColumn get world => text().nullable()();

  /// How many stickers + golden letters were earned the last time the
  /// album was opened (CLAUDE.md section 10, Refonte visuelle: the home
  /// screen's album icon shows a badge when this is lower than the
  /// current total). Null (never recorded yet) is read back as 0 by the
  /// repository — kept nullable, not `.withDefault()`, like the other
  /// optional columns above: under the web preview's degraded
  /// `sharedIndexedDb` persistence, a migration adding a non-nullable
  /// column with a SQL default did not reliably backfill it on the
  /// existing settings row, so every later read of this row (any
  /// column, not just this one) threw a null-check error from drift's
  /// generated row mapper — reproduced live, see CLAUDE.md section 13.
  IntColumn get albumLastSeenCount => integer().nullable()();

  /// Whether the home screen's first-visit hint ("touche le gros bouton
  /// pour jouer !", the mascot pointing at it) has already played once
  /// (CLAUDE.md section 10, Refonte visuelle) — shown only the first
  /// time. Null (never recorded) reads back as false — nullable rather
  /// than `.withDefault()`, for the same reason as [albumLastSeenCount]
  /// above.
  BoolColumn get hasShownPlayHint => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Where a sticker or golden letter was placed in the album's scene
/// (CLAUDE.md section 10, Refonte visuelle: "la maison du perroquet").
/// `dx`/`dy` are normalized (0..1) so a position survives a change of
/// screen size. Nothing writes to this table yet — the album computes a
/// spiral layout on the fly and falls back to it when a sticker has no
/// stored position — this table only exists so a future drag-and-drop
/// feature has somewhere to persist the child's own arrangement without
/// a schema change.
class StickerPositionRows extends Table {
  TextColumn get stickerId => text()();
  RealColumn get dx => real()();
  RealColumn get dy => real()();

  @override
  Set<Column> get primaryKey => {stickerId};
}

/// The best star count ever reached on one level (CLAUDE.md section 10:
/// each level on a path "garde ses meilleures étoiles obtenues"). A level
/// id is e.g. `fr.alphabet.pack2` or `fr.tracing.name` — see
/// `level_path.dart` for how these are built.
class LevelBestStarRows extends Table {
  TextColumn get levelId => text()();
  IntColumn get bestStars => integer()();

  @override
  Set<Column> get primaryKey => {levelId};
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
    LevelBestStarRows,
    StickerPositionRows,
  ],
)
class ProgressDatabase extends _$ProgressDatabase {
  ProgressDatabase(super.executor);

  // IMPORTANT (see CLAUDE.md section 7bis): any change to a table here —
  // a new column, a new table, a renamed one — must come with (1) a bump
  // of `schemaVersion` below, (2) its own `if (from < N)` step in
  // `migration.onUpgrade`, (3) a fresh schema dump in `drift_schemas/`
  // (`dart run drift_dev schema dump lib/core/progress/progress_database.dart
  // drift_schemas/`), and (4) the matching `SchemaVerifier` case in
  // `test/core/progress/progress_database_migration_test.dart`. Reusing an
  // existing version number for a new step is the exact bug reproduced
  // live and described below.
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await _createTableIfMissing(m, tracingGuidedSuccessDays);
        await _addColumnIfMissing(m, settingsRows, settingsRows.tracingQueueCursor);
      }
      if (from < 3) {
        await _addColumnIfMissing(m, settingsRows, settingsRows.world);
        await _createTableIfMissing(m, levelBestStarRows);
      }
      if (from < 4) {
        await _addColumnIfMissing(m, settingsRows, settingsRows.albumLastSeenCount);
        await _createTableIfMissing(m, stickerPositionRows);
      }
      // `schemaVersion` must go up every time a new migration step is
      // added here, even one that only reaches `hasShownPlayHint` — a
      // database already sitting at the version this step first shipped
      // under would otherwise never see `from < that version` become
      // true again, so `addColumn` would never run for it (reproduced
      // live: a browser profile stuck at schemaVersion 5 without the
      // physical `has_shown_play_hint` column, because that version
      // number was reused instead of bumped when this step was added).
      if (from < 6) {
        await _addColumnIfMissing(m, settingsRows, settingsRows.hasShownPlayHint);
      }
      // `albumLastSeenCount` was changed from non-nullable-with-default to
      // nullable without its own migration step (same root mistake as
      // above), so any install that was already at v4 or later before that
      // change shipped is physically stuck with `NOT NULL DEFAULT 0` on
      // that column forever — SQLite can't ALTER a column's constraint
      // directly, hence the full recreate via `alterTable` (caught by the
      // migration test suite: "migrates from v4" failed a strict schema
      // comparison, "NOT NULL DEFAULT 0" vs the nullable column the
      // current code expects — never observed as a runtime crash since a
      // concrete int reads back fine into a nullable Dart field, but a
      // real divergence from what the code declares).
      if (from < 7) {
        await m.alterTable(TableMigration(settingsRows));
      }
    },
    // Defensive, version-number-agnostic safety net (reproduced live: a
    // dev database can end up recorded at a version that matches
    // `schemaVersion` without every column above ever having actually
    // landed, e.g. from iterating on the schema with hot reloads before a
    // version bump was committed — `onUpgrade` above never even runs for
    // such a database, since drift only calls it when `from != to`). This
    // runs on every open regardless of the recorded version and repairs
    // any of these specific columns if still missing, so a corrupted dev
    // install self-heals instead of staying broken forever.
    beforeOpen: (details) async {
      final m = Migrator(this);
      await _addColumnIfMissing(m, settingsRows, settingsRows.tracingQueueCursor);
      await _addColumnIfMissing(m, settingsRows, settingsRows.world);
      await _addColumnIfMissing(m, settingsRows, settingsRows.albumLastSeenCount);
      await _addColumnIfMissing(m, settingsRows, settingsRows.hasShownPlayHint);
    },
  );

  Future<bool> _hasColumn(String table, String column) async {
    final info = await customSelect('PRAGMA table_info($table)').get();
    return info.any((row) => row.data['name'] == column);
  }

  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn column,
  ) async {
    if (!await _hasColumn(table.actualTableName, column.$name)) {
      await m.addColumn(table, column);
    }
  }

  Future<bool> _hasTable(String table) async {
    final info = await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable(table)],
    ).get();
    return info.isNotEmpty;
  }

  Future<void> _createTableIfMissing(Migrator m, TableInfo<Table, dynamic> table) async {
    if (!await _hasTable(table.actualTableName)) {
      await m.createTable(table);
    }
  }
}
