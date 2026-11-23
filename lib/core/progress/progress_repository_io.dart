import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'drift_progress_repository.dart';
import 'progress_database.dart';
import 'progress_repository.dart';

ProgressRepository createDefaultProgressRepository() {
  final executor = LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'progress.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
  return DriftProgressRepository(ProgressDatabase(executor));
}
