// The public constructor parameter is named `engine` (readable call sites),
// while the field is private `_engine`; an initializing formal would force
// the parameter itself to be named `_engine`.
// ignore_for_file: prefer_initializing_formals
import 'item_progress_snapshot.dart';
import 'item_state.dart';
import 'progress_repository.dart';
import 'progression_engine.dart';

/// Pure-Dart, non-persisted [ProgressRepository]. Used only for the web
/// dev preview (CLAUDE.md targets Android only; drift's native SQLite
/// backend needs `dart:ffi`, which a browser cannot run). Progress is
/// lost on reload and this is never used on a real device.
class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository({
    ProgressionEngine engine = const ProgressionEngine(),
  }) : _engine = engine;

  final ProgressionEngine _engine;
  final Map<String, ItemProgressSnapshot> _snapshots = {};

  @override
  Future<ItemProgressSnapshot> snapshotFor(String itemId) async {
    return _snapshots[itemId] ?? ItemProgressSnapshot(itemId: itemId);
  }

  @override
  Future<void> seed(String itemId, ItemState state) async {
    _snapshots[itemId] = ItemProgressSnapshot(itemId: itemId, state: state);
  }

  @override
  Future<ItemProgressSnapshot> recordAnswer({
    required String itemId,
    required bool correct,
    required bool firstTry,
    required DateTime today,
  }) async {
    final current = await snapshotFor(itemId);
    final next = _engine.recordAnswer(
      current: current,
      correct: correct,
      firstTry: firstTry,
      today: today,
    );
    _snapshots[itemId] = next;
    return next;
  }

  @override
  Future<Map<String, ItemState>> statesFor(List<String> itemIds) async {
    return {
      for (final id in itemIds)
        if (_snapshots.containsKey(id)) id: _snapshots[id]!.state,
    };
  }

  @override
  Future<void> dispose() async {}
}
