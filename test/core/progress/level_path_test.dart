import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/content/models/alphabet_item.dart';
import 'package:mboa_kids/core/content/models/word_ref.dart';
import 'package:mboa_kids/core/progress/item_state.dart';
import 'package:mboa_kids/core/progress/level_path.dart';

AlphabetItem _letter(String glyph) {
  return AlphabetItem(
    id: 'en.letter.$glyph',
    glyph: glyph,
    lower: glyph.toLowerCase(),
    audio: 'audio/en/letters/${glyph.toLowerCase()}.ogg',
    word: const WordRef(label: 'word', image: 'images/word.webp', audio: 'audio/word.ogg'),
  );
}

void main() {
  final alphabet = [for (final g in 'ABCDEFGHI'.split('')) _letter(g)];
  final startIds = {'en.letter.A', 'en.letter.B', 'en.letter.C'};

  group('buildPackLevelPath', () {
    test('the first pack after the start set is open, the rest locked', () {
      final levels = buildPackLevelPath(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: startIds,
        states: const {},
        packSize: 3,
      );

      expect(levels.map((l) => l.packNumber), [1, 2]);
      expect(levels[0].glyphs, ['D', 'E', 'F']);
      expect(levels[0].state, LevelState.open);
      expect(levels[1].glyphs, ['G', 'H', 'I']);
      expect(levels[1].state, LevelState.locked);
    });

    test('a pack whose items are all acquis is done', () {
      final states = {
        'en.letter.D': ItemState.acquis,
        'en.letter.E': ItemState.acquis,
        'en.letter.F': ItemState.acquis,
      };

      final levels = buildPackLevelPath(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: startIds,
        states: states,
        packSize: 3,
      );

      expect(levels[0].state, LevelState.done);
      expect(levels[1].state, LevelState.open, reason: 'unlocked once the first pack is acquis');
    });

    test('a partially-acquis pack is open, not done', () {
      final states = {
        'en.letter.D': ItemState.acquis,
        'en.letter.E': ItemState.enCours,
        'en.letter.F': ItemState.aApprendre,
      };

      final levels = buildPackLevelPath(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: startIds,
        states: states,
        packSize: 3,
      );

      expect(levels[0].state, LevelState.open);
    });

    test('passes each level its best stars from the given lookup', () {
      final levels = buildPackLevelPath(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: startIds,
        states: const {},
        packSize: 3,
        bestStarsFor: (packNumber) => packNumber == 1 ? 2 : 0,
      );

      expect(levels[0].bestStars, 2);
      expect(levels[1].bestStars, 0);
    });

    test('no levels at all once every letter is in the start set', () {
      final levels = buildPackLevelPath(
        allItemsInOrder: alphabet,
        startUnlockedItemIds: alphabet.map((i) => i.id).toSet(),
        states: const {},
        packSize: 3,
      );

      expect(levels, isEmpty);
    });
  });

  group('tracingNameLevelState', () {
    final itemIdByGlyph = {for (final item in alphabet) item.glyph: item.id};

    test('open while any name letter is not yet acquis', () {
      final state = tracingNameLevelState(
        firstName: 'ABC',
        itemIdByGlyph: itemIdByGlyph,
        states: const {'en.letter.A': ItemState.acquis},
      );

      expect(state, LevelState.open);
    });

    test('done once every name letter has reached acquis', () {
      final state = tracingNameLevelState(
        firstName: 'ABC',
        itemIdByGlyph: itemIdByGlyph,
        states: const {
          'en.letter.A': ItemState.acquis,
          'en.letter.B': ItemState.acquis,
          'en.letter.C': ItemState.acquis,
        },
      );

      expect(state, LevelState.done);
    });

    test('a repeated letter only needs to be acquis once', () {
      final state = tracingNameLevelState(
        firstName: 'ABBA',
        itemIdByGlyph: itemIdByGlyph,
        states: const {
          'en.letter.A': ItemState.acquis,
          'en.letter.B': ItemState.acquis,
        },
      );

      expect(state, LevelState.done);
    });

    test('an empty name is open, never locked, never done', () {
      expect(
        tracingNameLevelState(firstName: '', itemIdByGlyph: itemIdByGlyph, states: const {}),
        LevelState.open,
      );
    });
  });
}
