import 'dart:math';

import 'models/alphabet_item.dart';

/// One question of the "écoute et touche la lettre" game: the letter to
/// find, plus the choices shown (which include the target).
class AlphabetRound {
  const AlphabetRound({required this.target, required this.choices});

  final AlphabetItem target;
  final List<AlphabetItem> choices;

  /// "Mode aidé" (CLAUDE.md section 7): trims this round down to the
  /// target plus [otherChoicesCount] random distractors from the choices
  /// it already has, without re-running pool selection.
  AlphabetRound trimmedTo(int otherChoicesCount, Random random) {
    final others = [...choices.where((c) => c.id != target.id)]
      ..shuffle(random);
    final trimmed = [target, ...others.take(otherChoicesCount)]
      ..shuffle(random);
    return AlphabetRound(target: target, choices: trimmed);
  }
}
