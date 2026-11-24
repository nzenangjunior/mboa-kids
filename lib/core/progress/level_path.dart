import '../content/models/alphabet_item.dart';
import 'item_state.dart';
import 'pack_unlocker.dart';

/// Whether a level on a path can be played yet (CLAUDE.md section 10):
/// a circle on the path is locked, open (and pulses), or done (and shows
/// its best stars).
enum LevelState { locked, open, done }

/// One level on an island's path: 1 level = 1 pack of [glyphs] from the
/// content engine (CLAUDE.md section 10, "1 niveau = 1 paquet du moteur").
class PackLevel {
  const PackLevel({
    required this.packNumber,
    required this.glyphs,
    required this.state,
    required this.bestStars,
  });

  final int packNumber;
  final List<String> glyphs;
  final LevelState state;
  final int bestStars;
}

/// Builds the pack-based level path for one world's alphabet, reusing the
/// exact same pack-unlocking rules the alphabet game itself plays by
/// (CLAUDE.md section 7): a level is open once its pack is unlocked, done
/// once every item in it has reached `acquis`, locked otherwise. Levels
/// always come out in pack order, 1-based.
List<PackLevel> buildPackLevelPath({
  required List<AlphabetItem> allItemsInOrder,
  required Set<String> startUnlockedItemIds,
  required Map<String, ItemState> states,
  required int packSize,
  int Function(int packNumber)? bestStarsFor,
}) {
  final newItems = allItemsInOrder
      .where((i) => !startUnlockedItemIds.contains(i.id))
      .toList();
  if (newItems.isEmpty) return const [];

  final unlocker = PackUnlocker(packSize: packSize);
  final unlockedIds = unlocker.unlockedItemIds(
    orderedItemIds: allItemsInOrder.map((i) => i.id).toList(),
    alreadyUnlockedItemIds: startUnlockedItemIds,
    states: states,
  );

  final levels = <PackLevel>[];
  for (var i = 0; i < newItems.length; i += packSize) {
    final packItems = newItems.skip(i).take(packSize).toList();
    final packNumber = (i ~/ packSize) + 1;
    final isUnlocked = packItems.every((item) => unlockedIds.contains(item.id));
    final isDone = packItems.every((item) => states[item.id] == ItemState.acquis);
    final state = isDone
        ? LevelState.done
        : (isUnlocked ? LevelState.open : LevelState.locked);
    levels.add(
      PackLevel(
        packNumber: packNumber,
        glyphs: packItems.map((item) => item.glyph).toList(),
        state: state,
        bestStars: bestStarsFor?.call(packNumber) ?? 0,
      ),
    );
  }
  return levels;
}

/// The special first level of the tracing path: the child's first name
/// (CLAUDE.md section 7, "tracé dès le début"), never locked, done once
/// every one of its letters has reached `acquis`.
LevelState tracingNameLevelState({
  required String firstName,
  required Map<String, String> itemIdByGlyph,
  required Map<String, ItemState> states,
}) {
  final letters = firstName.toUpperCase().split('').where((c) => c.trim().isNotEmpty).toSet();
  if (letters.isEmpty) return LevelState.open;
  final allAcquired = letters.every((glyph) {
    final id = itemIdByGlyph[glyph];
    return id != null && states[id] == ItemState.acquis;
  });
  return allAcquired ? LevelState.done : LevelState.open;
}
