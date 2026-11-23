import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/tracing/tracing_glyph.dart';
import 'package:mboa_kids/core/tracing/tracing_matcher.dart';

/// A single straight horizontal stroke from (0.1, 0.5) to (0.9, 0.5), simple
/// enough to reason about exact distances in the tests below.
final _straightLine = TracingGlyph(
  glyph: 'line',
  strokes: const [
    TracingStroke([TracingPoint(0.1, 0.5), TracingPoint(0.9, 0.5)]),
  ],
);

List<Offset> _sampleAlongLine(double fromX, double toX, {int count = 20, double yOffset = 0}) {
  return [
    for (var i = 0; i < count; i++)
      Offset(fromX + (toX - fromX) * i / (count - 1), 0.5 + yOffset),
  ];
}

void main() {
  group('isGoodTrace', () {
    test('a trace that follows the whole guide closely passes', () {
      final drawn = _sampleAlongLine(0.1, 0.9);

      expect(isGoodTrace(glyph: _straightLine, drawnPoints: drawn), isTrue);
    });

    test('a wobbly trace within the wide tolerance still passes', () {
      final drawn = [
        for (var i = 0; i < 20; i++)
          Offset(0.1 + 0.8 * i / 19, 0.5 + (i.isEven ? 0.05 : -0.05)),
      ];

      expect(isGoodTrace(glyph: _straightLine, drawnPoints: drawn), isTrue);
    });

    test('a trace covering only half the guide fails coverage', () {
      final drawn = _sampleAlongLine(0.1, 0.45);

      expect(isGoodTrace(glyph: _straightLine, drawnPoints: drawn), isFalse);
    });

    test('a scribble far from the guide fails containment', () {
      final drawn = [
        for (var i = 0; i < 20; i++) Offset(0.05 + 0.02 * (i % 3), 0.05 + 0.02 * (i % 2)),
      ];

      expect(isGoodTrace(glyph: _straightLine, drawnPoints: drawn), isFalse);
    });

    test('fewer than two drawn points never passes', () {
      expect(isGoodTrace(glyph: _straightLine, drawnPoints: const []), isFalse);
      expect(
        isGoodTrace(glyph: _straightLine, drawnPoints: const [Offset(0.5, 0.5)]),
        isFalse,
      );
    });

    test('a glyph with no strokes never passes', () {
      const empty = TracingGlyph(glyph: 'empty', strokes: []);

      expect(
        isGoodTrace(glyph: empty, drawnPoints: _sampleAlongLine(0.1, 0.9)),
        isFalse,
      );
    });
  });

  group('densifyGlyph', () {
    test('samples points along every segment of every stroke', () {
      final dense = densifyGlyph(_straightLine, samplesPerSegment: 4);

      expect(dense.first, const Offset(0.1, 0.5));
      expect(dense.last, const Offset(0.9, 0.5));
      expect(dense.length, 5);
    });
  });
}
