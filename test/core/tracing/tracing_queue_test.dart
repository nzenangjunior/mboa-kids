import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/content/models/alphabet_item.dart';
import 'package:mboa_kids/core/content/models/word_ref.dart';
import 'package:mboa_kids/core/progress/item_state.dart';
import 'package:mboa_kids/core/tracing/tracing_queue.dart';

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
  final alphabet = [for (final g in 'ABCDEFG'.split('')) _letter(g)];

  test('the first name comes first, spelled out letter by letter, repeats included', () {
    final queue = buildTracingQueue(
      alphabetItems: alphabet,
      states: const {},
      firstName: 'ABBA',
      hasTracingData: (glyph) => true,
    );

    expect(queue.map((i) => i.glyph).take(4), ['A', 'B', 'B', 'A']);
  });

  test('letters never attempted (aApprendre) are excluded unless in the name', () {
    final states = {
      'en.letter.A': ItemState.aRevoir,
      'en.letter.B': ItemState.aApprendre,
      'en.letter.C': ItemState.enCours,
      'en.letter.D': ItemState.acquis,
      // E, F, G: no entry at all, same as a fresh aApprendre item.
    };

    final queue = buildTracingQueue(
      alphabetItems: alphabet,
      states: states,
      firstName: '',
      hasTracingData: (glyph) => true,
    );

    expect(queue.map((i) => i.glyph), ['A', 'C', 'D']);
  });

  test('a name letter that was never attempted is still included', () {
    final queue = buildTracingQueue(
      alphabetItems: alphabet,
      states: const {'en.letter.A': ItemState.aApprendre},
      firstName: 'A',
      hasTracingData: (glyph) => true,
    );

    expect(queue.map((i) => i.glyph), ['A']);
  });

  test('a recognized letter already covered by the name is not repeated', () {
    final queue = buildTracingQueue(
      alphabetItems: alphabet,
      states: {
        'en.letter.A': ItemState.acquis,
        'en.letter.B': ItemState.acquis,
      },
      firstName: 'A',
      hasTracingData: (glyph) => true,
    );

    expect(queue.map((i) => i.glyph), ['A', 'B']);
  });

  test('a glyph with no tracing data yet is skipped, name or not', () {
    final queue = buildTracingQueue(
      alphabetItems: alphabet,
      states: {'en.letter.C': ItemState.acquis},
      firstName: 'AB',
      hasTracingData: (glyph) => glyph != 'A' && glyph != 'C',
    );

    expect(queue.map((i) => i.glyph), ['B']);
  });

  test('a name letter outside the current alphabet is skipped', () {
    final queue = buildTracingQueue(
      alphabetItems: alphabet,
      states: const {},
      firstName: 'AZ',
      hasTracingData: (glyph) => true,
    );

    expect(queue.map((i) => i.glyph), ['A']);
  });
}
