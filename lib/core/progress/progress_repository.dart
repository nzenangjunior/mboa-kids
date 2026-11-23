import 'item_progress_snapshot.dart';
import 'item_state.dart';

/// Storage + progression-engine wiring for one item's progress.
///
/// Two implementations exist: [DriftProgressRepository] (real SQLite via
/// drift, used on Android and in tests) and [InMemoryProgressRepository]
/// (pure Dart, used only for the web dev preview — CLAUDE.md targets
/// Android only, and drift's native SQLite backend needs `dart:ffi`,
/// which is not available in a browser).
abstract class ProgressRepository {
  Future<ItemProgressSnapshot> snapshotFor(String itemId);

  /// Seeds an item directly into a given state, used for the English
  /// start set (A-E and 1-10 begin in `aRevoir`, CLAUDE.md section 7).
  Future<void> seed(String itemId, ItemState state);

  Future<ItemProgressSnapshot> recordAnswer({
    required String itemId,
    required bool correct,
    required bool firstTry,
    required DateTime today,
  });

  Future<Map<String, ItemState>> statesFor(List<String> itemIds);

  Future<void> dispose();
}
