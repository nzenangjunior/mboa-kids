import 'dart:ui';

import 'tracing_glyph.dart';

/// How closely a child's finger-drawn stroke must follow the guide for it
/// to count as a successful trace (CLAUDE.md section 10: "tolérance
/// large" — a 4-year-old's finger is not a stylus, and a strict match
/// would just be a wall nobody gets past).
class TracingTolerance {
  const TracingTolerance({
    this.coverageRadius = 0.16,
    this.containmentRadius = 0.22,
    this.minCoverageFraction = 0.7,
    this.minContainmentFraction = 0.75,
  });

  /// Every reference point within this distance (in the glyph's normalized
  /// 0..1 box) of at least one drawn point counts as "covered".
  final double coverageRadius;

  /// A drawn point within this distance of the nearest reference point
  /// counts as "on the letter" rather than a stray scribble.
  final double containmentRadius;

  /// Fraction of the reference path that must be covered.
  final double minCoverageFraction;

  /// Fraction of the drawn points that must stay on the letter.
  final double minContainmentFraction;
}

const defaultTracingTolerance = TracingTolerance();

/// Turns a glyph's key points into a dense reference path, so a short list
/// of key points (CLAUDE.md section 4: "points clés") still gives smooth
/// coverage checks along the whole stroke, not just at the key points
/// themselves.
List<Offset> densifyStroke(TracingStroke stroke, {int samplesPerSegment = 8}) {
  final points = stroke.points;
  if (points.length < 2) {
    return [for (final p in points) Offset(p.x, p.y)];
  }
  final dense = <Offset>[];
  for (var i = 0; i < points.length - 1; i++) {
    final a = Offset(points[i].x, points[i].y);
    final b = Offset(points[i + 1].x, points[i + 1].y);
    for (var s = 0; s < samplesPerSegment; s++) {
      dense.add(Offset.lerp(a, b, s / samplesPerSegment)!);
    }
  }
  final last = points.last;
  dense.add(Offset(last.x, last.y));
  return dense;
}

List<Offset> densifyGlyph(TracingGlyph glyph, {int samplesPerSegment = 8}) {
  return [
    for (final stroke in glyph.strokes)
      ...densifyStroke(stroke, samplesPerSegment: samplesPerSegment),
  ];
}

double _nearestDistance(Offset point, List<Offset> candidates) {
  var best = double.infinity;
  for (final candidate in candidates) {
    final d = (point - candidate).distance;
    if (d < best) best = d;
  }
  return best;
}

bool _isGoodMatch({
  required List<Offset> reference,
  required List<Offset> drawnPoints,
  required TracingTolerance tolerance,
}) {
  var covered = 0;
  for (final referencePoint in reference) {
    if (_nearestDistance(referencePoint, drawnPoints) <= tolerance.coverageRadius) {
      covered++;
    }
  }
  final coverageFraction = covered / reference.length;

  var contained = 0;
  for (final drawnPoint in drawnPoints) {
    if (_nearestDistance(drawnPoint, reference) <= tolerance.containmentRadius) {
      contained++;
    }
  }
  final containmentFraction = contained / drawnPoints.length;

  return coverageFraction >= tolerance.minCoverageFraction &&
      containmentFraction >= tolerance.minContainmentFraction;
}

/// Whether [drawnPoints] (normalized the same way as the guide, 0..1) is a
/// good enough trace of [glyph] as a whole.
///
/// Two checks, both with wide tolerance:
/// - coverage: most of the letter's path was actually gone over;
/// - containment: the finger mostly stayed on the letter rather than
///   scribbling anywhere on the screen (a few strays near the edges are
///   fine, which the tolerance and fraction thresholds absorb).
///
/// This only makes sense for a single continuous gesture covering every
/// stroke at once. A letter with several strokes (most letters) is drawn
/// stroke by stroke instead — see [isGoodStrokeTrace] — because a real
/// finger lifts between strokes (CLAUDE.md section 10).
bool isGoodTrace({
  required TracingGlyph glyph,
  required List<Offset> drawnPoints,
  TracingTolerance tolerance = defaultTracingTolerance,
}) {
  if (drawnPoints.length < 2) return false;
  final reference = densifyGlyph(glyph);
  if (reference.isEmpty) return false;
  return _isGoodMatch(reference: reference, drawnPoints: drawnPoints, tolerance: tolerance);
}

/// Whether [drawnPoints] (one continuous gesture, lifted at the end) is a
/// good enough trace of [referenceStroke] alone — the unit a real finger
/// actually draws in, lifting between strokes (CLAUDE.md section 10).
bool isGoodStrokeTrace({
  required TracingStroke referenceStroke,
  required List<Offset> drawnPoints,
  TracingTolerance tolerance = defaultTracingTolerance,
}) {
  if (drawnPoints.length < 2) return false;
  final reference = densifyStroke(referenceStroke);
  if (reference.isEmpty) return false;
  return _isGoodMatch(reference: reference, drawnPoints: drawnPoints, tolerance: tolerance);
}
