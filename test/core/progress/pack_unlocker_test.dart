import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/progress/item_state.dart';
import 'package:mboa_kids/core/progress/pack_unlocker.dart';

void main() {
  const unlocker = PackUnlocker(packSize: 3);
  final newItems = ['F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'];

  test('already-unlocked items are kept regardless of packs', () {
    final unlocked = unlocker.unlockedItemIds(
      orderedItemIds: ['A', 'B', 'C', 'D', 'E', ...newItems],
      alreadyUnlockedItemIds: {'A', 'B', 'C', 'D', 'E'},
      states: const {},
    );

    expect(unlocked, containsAll(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']));
    expect(unlocked, isNot(contains('I')));
  });

  test('the first pack of new items is always unlocked', () {
    final unlocked = unlocker.unlockedItemIds(
      orderedItemIds: newItems,
      alreadyUnlockedItemIds: const {},
      states: const {},
    );

    expect(unlocked, {'F', 'G', 'H'});
  });

  test('the next pack unlocks only once the current pack is fully acquis', () {
    final unlocked = unlocker.unlockedItemIds(
      orderedItemIds: newItems,
      alreadyUnlockedItemIds: const {},
      states: const {
        'F': ItemState.acquis,
        'G': ItemState.acquis,
        'H': ItemState.acquis,
      },
    );

    expect(unlocked, {'F', 'G', 'H', 'I', 'J', 'K'});
  });

  test('a partially acquis pack does not unlock the next one', () {
    final unlocked = unlocker.unlockedItemIds(
      orderedItemIds: newItems,
      alreadyUnlockedItemIds: const {},
      states: const {'F': ItemState.acquis, 'G': ItemState.acquis},
    );

    expect(unlocked, {'F', 'G', 'H'});
  });

  test('unlocking can cascade through several fully acquis packs', () {
    final unlocked = unlocker.unlockedItemIds(
      orderedItemIds: newItems,
      alreadyUnlockedItemIds: const {},
      states: const {
        'F': ItemState.acquis,
        'G': ItemState.acquis,
        'H': ItemState.acquis,
        'I': ItemState.acquis,
        'J': ItemState.acquis,
        'K': ItemState.acquis,
      },
    );

    expect(unlocked, {'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N'});
  });
}
