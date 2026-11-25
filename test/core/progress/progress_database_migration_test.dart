// Official drift migration tests (CLAUDE.md section 7bis): every historical
// schema version this app ever shipped (1 through the current one) must be
// able to upgrade cleanly to the latest schema, and real data already sitting
// in the oldest version must survive the whole chain intact. This is what
// actually would have caught the `hasShownPlayHint` migration bug — reading
// the migration code and reasoning "this looks right" did not.
//
// `test/generated_migrations/` is generated from `drift_schemas/*.json` via:
//   dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
// Re-run that whenever `drift_schemas/` gains a new version.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/progress/progress_database.dart';

import '../../generated_migrations/schema.dart';
import '../../generated_migrations/schema_v1.dart' as v1;

void main() {
  final verifier = SchemaVerifier(GeneratedHelper());
  final latestVersion = GeneratedHelper.versions.length;

  for (final fromVersion in GeneratedHelper.versions) {
    test(
      'migrates from v$fromVersion to the current schema (v$latestVersion) without error',
      () async {
        final connection = await verifier.startAt(fromVersion);
        final db = ProgressDatabase(connection);
        addTearDown(db.close);

        await verifier.migrateAndValidate(db, latestVersion);
      },
    );
  }

  test(
    'a settings row created on the very first schema (v1) survives the full '
    'migration chain to the current schema, with the columns added along the '
    'way defaulting the way the repository expects',
    () async {
      await verifier.testWithDataIntegrity(
        oldVersion: 1,
        newVersion: latestVersion,
        createOld: (executor) => v1.DatabaseAtV1(executor),
        createNew: (executor) => ProgressDatabase(executor),
        openTestedDatabase: (executor) => ProgressDatabase(executor),
        createItems: (batch, oldDb) {
          batch.insert(
            oldDb.settingsRows,
            v1.SettingsRowsCompanion.insert(
              id: const Value(0),
              intensity: const Value('fete'),
            ),
          );
        },
        validateItems: (newDb) async {
          final row = await (newDb.select(
            newDb.settingsRows,
          )..where((t) => t.id.equals(0))).getSingle();

          expect(row.intensity, 'fete', reason: 'pre-existing data must not be lost');
          expect(
            row.hasShownPlayHint,
            isNull,
            reason:
                'a column added after this row existed must read back as the '
                'nullable "never recorded" state, not crash the read',
          );
          expect(row.albumLastSeenCount, isNull);
          expect(row.tracingQueueCursor, isNull);
          expect(row.world, isNull);
        },
      );
    },
  );
}
