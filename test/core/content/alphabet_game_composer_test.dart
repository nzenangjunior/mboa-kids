import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/content/alphabet_game_composer.dart';
import 'package:mboa_kids/core/content/models/alphabet_item.dart';
import 'package:mboa_kids/core/content/models/word_ref.dart';
import 'package:mboa_kids/core/progress/item_state.dart';

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
  final alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map(_letter).toList();
  final startIds = {
    'en.letter.A',
    'en.letter.B',
    'en.letter.C',
    'en.letter.D',
    'en.letter.E',
  };

  String letterOf(String itemId) => itemId.split('.').last;

  test('a fresh English profile never shows a letter past H', () {
    final states = {for (final id in startIds) id: ItemState.aRevoir};

    for (var seed = 0; seed < 30; seed++) {
      final rounds = AlphabetGameComposer(random: Random(seed)).buildGame(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: startIds,
        states: states,
      );

      for (final round in rounds) {
        final idsShown = [round.target.id, ...round.choices.map((c) => c.id)];
        for (final id in idsShown) {
          expect(
            'ABCDEFGH'.contains(letterOf(id)),
            isTrue,
            reason: 'Unexpected letter ${letterOf(id)} beyond the unlocked F-G-H pack',
          );
        }
      }
    }
  });

  test('wrong-answer choices never include a locked letter', () {
    final states = {
      for (final id in startIds) id: ItemState.aRevoir,
      'en.letter.F': ItemState.enCours,
    };

    for (var seed = 0; seed < 20; seed++) {
      final rounds = AlphabetGameComposer(random: Random(seed)).buildGame(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: startIds,
        states: states,
      );

      for (final round in rounds) {
        for (final choice in round.choices) {
          expect('ABCDEFGH'.contains(letterOf(choice.id)), isTrue);
        }
      }
    }
  });

  test('the next pack (I-J-K) unlocks once F-G-H is fully acquis', () {
    final states = {
      for (final id in startIds) id: ItemState.aRevoir,
      'en.letter.F': ItemState.acquis,
      'en.letter.G': ItemState.acquis,
      'en.letter.H': ItemState.acquis,
    };

    final pool = AlphabetGameComposer().unlockedPool(
      allItemsInOrder: alphabet,
      startUnlockedItemIds: startIds,
      states: states,
    );

    expect(
      pool.map((i) => letterOf(i.id)).toSet(),
      {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K'},
    );
  });

  test('the first question is always a review, not a brand-new letter', () {
    final states = {for (final id in startIds) id: ItemState.aRevoir};

    for (var seed = 0; seed < 20; seed++) {
      final rounds = AlphabetGameComposer(random: Random(seed)).buildGame(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: startIds,
        states: states,
      );

      expect(states[rounds.first.target.id], isNot(ItemState.aApprendre));
    }
  });

  test('about 1 in 5 questions introduces a brand-new letter', () {
    final states = {
      for (final id in startIds) id: ItemState.aRevoir,
      'en.letter.F': ItemState.aApprendre,
      'en.letter.G': ItemState.aApprendre,
      'en.letter.H': ItemState.aApprendre,
    };

    final rounds = AlphabetGameComposer(random: Random(7)).buildGame(
      allItemsInOrder: alphabet,
      startUnlockedItemIds: startIds,
      states: states,
    );

    final newCount = rounds
        .where((r) => states[r.target.id] == ItemState.aApprendre)
        .length;
    expect(newCount, inInclusiveRange(1, 2));
  });

  test('buildRoundFor targets the exact item requested', () {
    final pool = alphabet.take(8).toList();
    final target = pool[3];

    final round = AlphabetGameComposer(random: Random(5)).buildRoundFor(target, pool);

    expect(round.target.id, target.id);
    expect(round.choices.map((c) => c.id), contains(target.id));
    expect(round.choices, hasLength(3));
  });

  group('startUnlockedAlphabetItemIds', () {
    test('is A-E for English', () {
      expect(
        startUnlockedAlphabetItemIds('en', alphabet),
        {'en.letter.A', 'en.letter.B', 'en.letter.C', 'en.letter.D', 'en.letter.E'},
      );
    });

    test('is empty for French (discovery game not implemented yet)', () {
      expect(startUnlockedAlphabetItemIds('fr', alphabet), isEmpty);
    });
  });

  group('packNumberFor', () {
    final orderedIds = alphabet.map((i) => i.id).toList();

    test('is null for a start item', () {
      expect(
        packNumberFor(
          'en.letter.A',
          orderedItemIds: orderedIds,
          startUnlockedItemIds: startIds,
          packSize: 3,
        ),
        isNull,
      );
    });

    test('numbers the first pack of new items 1', () {
      for (final id in ['en.letter.F', 'en.letter.G', 'en.letter.H']) {
        expect(
          packNumberFor(
            id,
            orderedItemIds: orderedIds,
            startUnlockedItemIds: startIds,
            packSize: 3,
          ),
          1,
        );
      }
    });

    test('numbers the second pack of new items 2', () {
      for (final id in ['en.letter.I', 'en.letter.J', 'en.letter.K']) {
        expect(
          packNumberFor(
            id,
            orderedItemIds: orderedIds,
            startUnlockedItemIds: startIds,
            packSize: 3,
          ),
          2,
        );
      }
    });
  });

  group('itemsInPack / buildGameForPack (level path, CLAUDE.md section 10)', () {
    test('itemsInPack returns the exact glyphs of a given pack', () {
      final composer = AlphabetGameComposer();

      final pack1 = composer.itemsInPack(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: startIds,
        packNumber: 1,
      );
      final pack2 = composer.itemsInPack(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: startIds,
        packNumber: 2,
      );

      expect(pack1.map((i) => i.glyph), ['F', 'G', 'H']);
      expect(pack2.map((i) => i.glyph), ['I', 'J', 'K']);
    });

    test('itemsInPack is empty past the last pack', () {
      final composer = AlphabetGameComposer();

      final pack = composer.itemsInPack(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: startIds,
        packNumber: 999,
      );

      expect(pack, isEmpty);
    });

    test('buildGameForPack only ever targets that pack\'s letters', () {
      final states = {for (final id in startIds) id: ItemState.aRevoir};

      for (var seed = 0; seed < 20; seed++) {
        final rounds = AlphabetGameComposer(random: Random(seed)).buildGameForPack(
          allItemsInOrder: alphabet,
          startUnlockedItemIds: startIds,
          states: states,
          packNumber: 1,
        );

        expect(rounds, hasLength(5));
        for (final round in rounds) {
          expect(['F', 'G', 'H'], contains(round.target.glyph));
        }
      }
    });

    test('buildGameForPack still draws distractors from the whole unlocked pool', () {
      final states = {for (final id in startIds) id: ItemState.aRevoir};

      final rounds = AlphabetGameComposer(random: Random(1)).buildGameForPack(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: startIds,
        states: states,
        packNumber: 1,
      );

      final allChoiceGlyphs = rounds.expand((r) => r.choices.map((c) => c.glyph)).toSet();
      expect(
        allChoiceGlyphs.any((g) => startIds.any((id) => id.endsWith('.$g'))),
        isTrue,
        reason: 'distractors should be able to come from the start set too, not just the pack',
      );
    });

    test('buildGameForPack throws for a pack that does not exist', () {
      expect(
        () => AlphabetGameComposer().buildGameForPack(
          allItemsInOrder: alphabet,
          startUnlockedItemIds: startIds,
          states: const {},
          packNumber: 999,
        ),
        throwsArgumentError,
      );
    });
  });
}
