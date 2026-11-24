import 'dart:math';

import '../progress/item_state.dart';
import '../progress/pack_unlocker.dart';
import 'alphabet_round.dart';
import 'models/alphabet_item.dart';

/// English start set (CLAUDE.md section 7): A-E begin directly in
/// `aRevoir`, as already-known review material, rather than going
/// through the normal pack-unlocking path. French doesn't have its
/// discovery game implemented yet (CLAUDE.md section 10, Structure step —
/// still outstanding), so for now it starts with nothing pre-known.
/// Shared by the game screen and the debug panel so both agree on what
/// "unlocked" means.
Set<String> startUnlockedAlphabetItemIds(String world, List<AlphabetItem> items) {
  if (world != 'en') return const {};
  const startGlyphs = {'A', 'B', 'C', 'D', 'E'};
  return items
      .where((i) => startGlyphs.contains(i.glyph))
      .map((i) => i.id)
      .toSet();
}

/// 1-based pack number for [itemId] among the items not already in
/// [startUnlockedItemIds], grouped by [packSize] (CLAUDE.md section 7:
/// "Nouveaux items par paquets de 3"). Returns null for a start item,
/// which isn't part of the pack sequence at all.
int? packNumberFor(
  String itemId, {
  required List<String> orderedItemIds,
  required Set<String> startUnlockedItemIds,
  required int packSize,
}) {
  if (startUnlockedItemIds.contains(itemId)) return null;
  final newIds = orderedItemIds
      .where((id) => !startUnlockedItemIds.contains(id))
      .toList();
  final index = newIds.indexOf(itemId);
  if (index == -1) return null;
  return (index ~/ packSize) + 1;
}

/// Builds a full alphabet game from the real progression state
/// (CLAUDE.md section 7): only already-unlocked letters are ever shown,
/// the first question is a review, the rest mixes roughly 2 known letters
/// for every new one, and wrong-answer choices are always picked from the
/// unlocked pool too (never a letter the child hasn't met yet).
class AlphabetGameComposer {
  AlphabetGameComposer({
    Random? random,
    this.packUnlocker = const PackUnlocker(),
    this.questionCount = 5,
    this.choiceCount = 3,
  }) : _random = random ?? Random();

  final Random _random;
  final PackUnlocker packUnlocker;
  final int questionCount;
  final int choiceCount;

  /// Every letter currently available to the child: [startUnlockedItemIds]
  /// (e.g. the English A-E start set) plus whatever packs of 3 the
  /// progression in [states] has unlocked beyond them.
  List<AlphabetItem> unlockedPool({
    required List<AlphabetItem> allItemsInOrder,
    required Set<String> startUnlockedItemIds,
    required Map<String, ItemState> states,
  }) {
    final unlockedIds = packUnlocker.unlockedItemIds(
      orderedItemIds: allItemsInOrder.map((i) => i.id).toList(),
      alreadyUnlockedItemIds: startUnlockedItemIds,
      states: states,
    );
    return allItemsInOrder.where((i) => unlockedIds.contains(i.id)).toList();
  }

  List<AlphabetRound> buildGame({
    required List<AlphabetItem> allItemsInOrder,
    required Set<String> startUnlockedItemIds,
    required Map<String, ItemState> states,
  }) {
    final pool = unlockedPool(
      allItemsInOrder: allItemsInOrder,
      startUnlockedItemIds: startUnlockedItemIds,
      states: states,
    );
    if (pool.length < choiceCount) {
      throw ArgumentError(
        'Need at least $choiceCount unlocked items to build a game, got ${pool.length}',
      );
    }

    final known = pool
        .where((i) => (states[i.id] ?? ItemState.aApprendre) != ItemState.aApprendre)
        .toList();
    final fresh = pool
        .where((i) => (states[i.id] ?? ItemState.aApprendre) == ItemState.aApprendre)
        .toList();

    var newLeft = fresh.isEmpty ? 0 : (questionCount / 3).round();
    final targets = <AlphabetItem>[];

    for (var i = 0; i < questionCount; i++) {
      // The first question is always a review (CLAUDE.md section 7).
      final wantNew = i != 0 && newLeft > 0 && fresh.isNotEmpty;
      if (wantNew) {
        targets.add(fresh[_random.nextInt(fresh.length)]);
        newLeft--;
      } else if (known.isNotEmpty) {
        targets.add(known[_random.nextInt(known.length)]);
      } else {
        targets.add(fresh[_random.nextInt(fresh.length)]);
      }
    }

    return targets.map((target) => buildRoundFor(target, pool)).toList();
  }

  /// The items belonging to pack [packNumber] (1-based, CLAUDE.md section
  /// 10: "1 niveau = 1 paquet du moteur"), empty if that pack doesn't
  /// exist. Mirrors [packNumberFor]'s own grouping so a level on the path
  /// always matches the game it launches.
  List<AlphabetItem> itemsInPack({
    required List<AlphabetItem> allItemsInOrder,
    required Set<String> startUnlockedItemIds,
    required int packNumber,
  }) {
    final newItems = allItemsInOrder
        .where((i) => !startUnlockedItemIds.contains(i.id))
        .toList();
    final startIndex = (packNumber - 1) * packUnlocker.packSize;
    if (startIndex < 0 || startIndex >= newItems.length) return const [];
    return newItems.skip(startIndex).take(packUnlocker.packSize).toList();
  }

  /// Builds a game whose questions are only drawn from pack [packNumber]
  /// (a level on the path, CLAUDE.md section 10), while distractor choices
  /// still come from the whole unlocked pool, same as [buildRoundFor].
  List<AlphabetRound> buildGameForPack({
    required List<AlphabetItem> allItemsInOrder,
    required Set<String> startUnlockedItemIds,
    required Map<String, ItemState> states,
    required int packNumber,
  }) {
    final packItems = itemsInPack(
      allItemsInOrder: allItemsInOrder,
      startUnlockedItemIds: startUnlockedItemIds,
      packNumber: packNumber,
    );
    if (packItems.isEmpty) {
      throw ArgumentError('No items in pack $packNumber');
    }
    final pool = unlockedPool(
      allItemsInOrder: allItemsInOrder,
      startUnlockedItemIds: startUnlockedItemIds,
      states: states,
    );
    if (pool.length < choiceCount) {
      throw ArgumentError(
        'Need at least $choiceCount unlocked items to build a game, got ${pool.length}',
      );
    }
    final targets = [
      for (var i = 0; i < questionCount; i++) packItems[_random.nextInt(packItems.length)],
    ];
    return targets.map((target) => buildRoundFor(target, pool)).toList();
  }

  /// Builds a single round for a specific [target] (used for the
  /// immediate retry and the end-of-game reappearance after a wrong
  /// answer), with distractors from [pool] only.
  AlphabetRound buildRoundFor(AlphabetItem target, List<AlphabetItem> pool) {
    final distractors = [...pool.where((i) => i.id != target.id)]
      ..shuffle(_random);
    if (distractors.length < choiceCount - 1) {
      throw ArgumentError(
        'Need at least ${choiceCount - 1} other unlocked items for distractors, '
        'got ${distractors.length}',
      );
    }
    final choices = [target, ...distractors.take(choiceCount - 1)]
      ..shuffle(_random);
    return AlphabetRound(target: target, choices: choices);
  }
}
