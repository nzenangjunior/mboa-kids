import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  DateTimeColumn get acquiredAt => dateTime().nullable()();
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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'progress.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(tables: [ItemProgressRows, CorrectFirstTryDays])
class ProgressDatabase extends _$ProgressDatabase {
  ProgressDatabase() : super(_openConnection());
  ProgressDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}
