import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

import 'drift_progress_repository.dart';
import 'progress_database.dart';
import 'progress_repository.dart';

/// Real SQLite persistence for the web dev preview, via sqlite3 compiled
/// to WebAssembly (CLAUDE.md targets Android only; this is purely so
/// progress survives in the browser while there is no tablet at hand).
/// `web/sqlite3.wasm` and `web/drift_worker.js` are drift's own prebuilt
/// files, copied from its devtools extension assets — no need to fetch
/// anything from the network to set this up.
ProgressRepository createDefaultProgressRepository() {
  final executor = LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'mboa_kids_progress',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    if (result.missingFeatures.isNotEmpty) {
      debugPrint(
        '[ProgressRepository] Persistance web réduite '
        '(${result.chosenImplementation.name}) : fonctionnalités '
        'navigateur manquantes : ${result.missingFeatures}.',
      );
    } else {
      debugPrint(
        '[ProgressRepository] Persistance web : '
        '${result.chosenImplementation.name}.',
      );
    }

    return result.resolvedExecutor;
  });

  return DriftProgressRepository(ProgressDatabase(executor));
}
