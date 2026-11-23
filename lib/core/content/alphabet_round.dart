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

/// Builds alphabet game rounds. Pure selection logic, kept out of widgets
/// per CLAUDE.md section 11 so it can be unit tested on its own.
class AlphabetRoundBuilder {
  AlphabetRoundBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Picks [choiceCount] distinct items from [pool] and designates one of
  /// them as the target.
  AlphabetRound build(List<AlphabetItem> pool, {int choiceCount = 3}) {
    if (pool.length < choiceCount) {
      throw ArgumentError(
        'Need at least $choiceCount items to build a round, got ${pool.length}',
      );
    }
    final choices = [...pool]..shuffle(_random);
    final selected = choices.take(choiceCount).toList();
    final target = selected[_random.nextInt(selected.length)];
    selected.shuffle(_random);
    return AlphabetRound(target: target, choices: selected);
  }

  /// Builds a full game: [questionCount] rounds (5 by default, per
  /// CLAUDE.md section 7: "Un jeu = 5 questions").
  List<AlphabetRound> buildGame(
    List<AlphabetItem> pool, {
    int questionCount = 5,
    int choiceCount = 3,
  }) {
    return List.generate(
      questionCount,
      (_) => build(pool, choiceCount: choiceCount),
    );
  }
}
