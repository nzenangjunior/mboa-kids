import 'drift_progress_repository.dart';
import 'progress_database.dart';
import 'progress_repository.dart';

ProgressRepository createDefaultProgressRepository() {
  return DriftProgressRepository(ProgressDatabase());
}
