import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/content/models/alphabet_item.dart';
import 'package:mboa_kids/core/content/models/number_item.dart';
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

  group('buildNumberTracingQueue', () {
    const numbers = NumbersContent(
      world: 'fr',
      recognize: [NumberTier(0, 20)],
      countObjectsMax: 20,
      writeMax: 5,
      countByTensMax: 100,
    );

    test('every digit up to writeMax with tracing data is included, in order', () {
      final queue = buildNumberTracingQueue(
        numbersContent: numbers,
        hasTracingData: (glyph) => true,
      );

      expect(queue.map((i) => i.value), [1, 2, 3, 4, 5]);
      expect(queue.first.id, 'fr.number.1');
    });

    test('a digit with no tracing data yet is skipped', () {
      final queue = buildNumberTracingQueue(
        numbersContent: numbers,
        hasTracingData: (glyph) => glyph != '3',
      );

      expect(queue.map((i) => i.value), [1, 2, 4, 5]);
    });

    test('digits beyond writeMax are never offered, even with tracing data', () {
      const wide = NumbersContent(
        world: 'fr',
        recognize: [NumberTier(0, 20)],
        countObjectsMax: 20,
        writeMax: 2,
        countByTensMax: 100,
      );

      final queue = buildNumberTracingQueue(
        numbersContent: wide,
        hasTracingData: (glyph) => true,
      );

      expect(queue.map((i) => i.value), [1, 2]);
    });
  });

  group('selectTracingSessionQueue', () {
    List<TracingQueueItem> items(List<String> ids) =>
        [for (final id in ids) TracingQueueItem(id: id, glyphKey: id)];

    test('with no cursor, starts from the beginning and caps at 5', () {
      final queue = items(['A', 'B', 'C', 'D', 'E', 'F', 'G']);

      final session = selectTracingSessionQueue(queue);

      expect(session.map((s) => s.item.id), ['A', 'B', 'C', 'D', 'E']);
    });

    test('resumes right after the cursor', () {
      final queue = items(['A', 'B', 'C', 'D', 'E', 'F', 'G']);

      final session = selectTracingSessionQueue(queue, afterCursor: 'C#1');

      expect(session.map((s) => s.item.id), ['D', 'E', 'F', 'G', 'A']);
    });

    test(
      'with fewer eligible items than the session cap, wraps around to '
      'fill the session but never lists the same item twice',
      () {
        final queue = items(['A', 'B', 'C']);

        final session = selectTracingSessionQueue(queue, afterCursor: 'B#1');

        expect(session.map((s) => s.item.id), ['C', 'A', 'B']);
        expect(session.map((s) => s.item.id).toSet(), hasLength(3));
      },
    );

    test('a cursor no longer found in the queue restarts from the beginning', () {
      final queue = items(['A', 'B', 'C']);

      final session = selectTracingSessionQueue(queue, afterCursor: 'Z#1');

      expect(session.map((s) => s.item.id), ['A', 'B', 'C']);
    });

    test(
      'a repeated id (e.g. the two E in ESTRELLA) is disambiguated by occurrence, '
      'so resuming after the first E does not skip the second',
      () {
        final queue = items(['E', 'S', 'T', 'R', 'E', 'L', 'L', 'A']);

        final afterFirstE = selectTracingSessionQueue(queue, afterCursor: 'E#1');
        expect(afterFirstE.map((s) => s.item.id), ['S', 'T', 'R', 'E', 'L']);
        expect(afterFirstE[3].occurrenceKey, 'E#2');

        final afterSecondE = selectTracingSessionQueue(queue, afterCursor: 'E#2');
        expect(afterSecondE.map((s) => s.item.id), ['L', 'L', 'A', 'E', 'S']);
      },
    );

    test('an empty queue selects nothing', () {
      expect(selectTracingSessionQueue(const []), isEmpty);
    });
  });

  group('buildFullTracingQueue', () {
    const numbers = NumbersContent(
      world: 'fr',
      recognize: [NumberTier(0, 20)],
      countObjectsMax: 20,
      writeMax: 3,
      countByTensMax: 100,
    );

    test('letters (name first) come before numbers', () {
      final queue = buildFullTracingQueue(
        alphabetItems: alphabet,
        states: const {'en.letter.C': ItemState.acquis},
        firstName: 'A',
        numbersContent: numbers,
        hasTracingData: (glyph) => true,
      );

      expect(queue.map((i) => i.glyphKey), ['A', 'C', '1', '2', '3']);
      expect(queue.map((i) => i.id), [
        'en.letter.A',
        'en.letter.C',
        'fr.number.1',
        'fr.number.2',
        'fr.number.3',
      ]);
    });
  });
}
