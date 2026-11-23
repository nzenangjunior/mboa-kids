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

/// This schema has no platform-specific connection logic of its own: how to
/// actually open it (native SQLite file on Android/desktop, or SQLite
/// compiled to WebAssembly on the web dev preview) lives in
/// `progress_repository_io.dart` / `progress_repository_web.dart`, so that
/// this file never pulls in `dart:io` or `dart:ffi` and stays safe to
/// import from web-compiled code.
@DriftDatabase(tables: [ItemProgressRows, CorrectFirstTryDays])
class ProgressDatabase extends _$ProgressDatabase {
  ProgressDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
