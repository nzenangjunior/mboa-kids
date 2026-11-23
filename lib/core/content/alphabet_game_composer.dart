import 'dart:math';

import '../progress/item_state.dart';
import '../progress/pack_unlocker.dart';
import 'alphabet_round.dart';
import 'models/alphabet_item.dart';

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
