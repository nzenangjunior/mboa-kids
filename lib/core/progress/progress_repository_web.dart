import 'in_memory_progress_repository.dart';
import 'progress_repository.dart';

ProgressRepository createDefaultProgressRepository() {
  return InMemoryProgressRepository();
}
