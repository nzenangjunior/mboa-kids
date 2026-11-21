import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/content/alphabet_round.dart';
import 'package:mboa_kids/core/content/models/alphabet_item.dart';
import 'package:mboa_kids/core/content/models/word_ref.dart';

AlphabetItem _letter(String glyph) {
  return AlphabetItem(
    id: 'en.letter.$glyph',
    glyph: glyph,
    lower: glyph.toLowerCase(),
    audio: 'audio/en/letters/${glyph.toLowerCase()}.ogg',
    word: WordRef(
      label: glyph,
      image: 'images/vocab/$glyph.webp',
      audio: 'audio/en/words/$glyph.ogg',
    ),
  );
}

void main() {
  final pool = ['A', 'B', 'C', 'D', 'E'].map(_letter).toList();

  group('build', () {
    test('returns the requested number of choices', () {
      final round = AlphabetRoundBuilder(random: Random(1)).build(pool);

      expect(round.choices, hasLength(3));
    });

    test('the target is always one of the choices', () {
      for (var seed = 0; seed < 20; seed++) {
        final round = AlphabetRoundBuilder(random: Random(seed)).build(pool);
        expect(round.choices.map((c) => c.id), contains(round.target.id));
      }
    });

    test('choices are distinct items from the pool', () {
      final round = AlphabetRoundBuilder(random: Random(2)).build(pool);
      final ids = round.choices.map((c) => c.id).toSet();

      expect(ids, hasLength(round.choices.length));
      for (final choice in round.choices) {
        expect(pool.map((p) => p.id), contains(choice.id));
      }
    });

    test('throws when the pool is smaller than choiceCount', () {
      expect(
        () => AlphabetRoundBuilder().build(pool.take(2).toList()),
        throwsArgumentError,
      );
    });
  });

  group('buildGame', () {
    test('returns 5 rounds by default', () {
      final rounds = AlphabetRoundBuilder(random: Random(3)).buildGame(pool);

      expect(rounds, hasLength(5));
      for (final round in rounds) {
        expect(round.choices, hasLength(3));
      }
    });

    test('honors a custom question count', () {
      final rounds = AlphabetRoundBuilder(
        random: Random(4),
      ).buildGame(pool, questionCount: 2);

      expect(rounds, hasLength(2));
    });
  });
}
