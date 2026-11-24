import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/tracing/tracing_glyph.dart';
import '../../core/tracing/tracing_matcher.dart';

/// Draws the dotted letter guide (with a start dot and a direction arrow
/// per stroke, CLAUDE.md section 10), the strokes the child has already
/// completed (kept, solid), the one stroke currently being drawn, and —
/// during a replay — a traveling marker over just the stroke being
/// demonstrated. A letter is drawn stroke by stroke, lifting the finger
/// between strokes, so each of these is tracked independently rather than
/// as one flat list of points.
class TracingCanvasPainter extends CustomPainter {
  TracingCanvasPainter({
    required this.glyph,
    required this.completedStrokes,
    required this.currentStrokePoints,
    required this.success,
    this.showGuide = true,
    this.nextStrokeIndex,
    this.blinkValue = 0,
    this.replayStrokeIndex,
    this.replayProgress,
  });

  final TracingGlyph glyph;

  /// One list of normalized (0..1) points per stroke already matched —
  /// kept on screen even if a later stroke fails, since only a fresh
  /// attempt at that later stroke should be replayed, not this one.
  final List<List<Offset>> completedStrokes;

  /// The points of the stroke currently being drawn (the finger is still
  /// down, or just lifted and awaiting the match result).
  final List<Offset> currentStrokePoints;

  /// Whether every stroke has now been matched.
  final bool success;

  /// Whether the dotted guide (path, start dot, arrow) is visible. False
  /// once a letter has been traced correctly once and moves to the
  /// "sans guide" reinforcement pass (CLAUDE.md section 10).
  final bool showGuide;

  /// The stroke the child is expected to draw next, whose start dot
  /// pulses to show where to begin (only while [showGuide] is true: a
  /// "sans guide" pass gives no such hint).
  final int? nextStrokeIndex;

  /// 0..1 animation phase driving the pulse on [nextStrokeIndex]'s dot.
  final double blinkValue;

  /// When [replayProgress] is non-null (0..1), a traveling marker
  /// demonstrates this one stroke again after a failed attempt — the
  /// guide for it is always shown while this plays, even in "sans guide"
  /// mode, so the demo makes sense. Already-completed strokes are
  /// untouched: only the stroke that failed is replayed.
  final int? replayStrokeIndex;
  final double? replayProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGuide || replayProgress != null) {
      _paintGuide(canvas, size);
    }
    _paintStrokePoints(canvas, size, completedStrokes, color: Colors.green.shade600);
    _paintStrokePoints(
      canvas,
      size,
      [currentStrokePoints],
      color: success ? Colors.green.shade600 : MboaKidsTheme.pink,
    );
    if (replayProgress != null && replayStrokeIndex != null) {
      _paintReplayMarker(canvas, size, glyph.strokes[replayStrokeIndex!], replayProgress!);
    }
  }

  void _paintReplayMarker(Canvas canvas, Size size, TracingStroke stroke, double progress) {
    final dense = densifyStroke(stroke);
    if (dense.isEmpty) return;
    final t = progress.clamp(0.0, 1.0) * (dense.length - 1);
    final index = t.floor().clamp(0, dense.length - 1);
    final nextIndex = (index + 1).clamp(0, dense.length - 1);
    final point = Offset.lerp(dense[index], dense[nextIndex], t - index)!;
    final markerPaint = Paint()..color = Colors.orange.shade600;
    canvas.drawCircle(_scaleOffset(point, size), 18, markerPaint);
  }

  Offset _scalePoint(TracingPoint point, Size size) {
    return Offset(point.x * size.width, point.y * size.height);
  }

  Offset _scaleOffset(Offset point, Size size) {
    return Offset(point.dx * size.width, point.dy * size.height);
  }

  void _paintGuide(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = MboaKidsTheme.lightPurple
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final startDotPaint = Paint()..color = Colors.green.shade400;
    final arrowPaint = Paint()..color = Colors.green.shade400;

    for (var i = 0; i < glyph.strokes.length; i++) {
      final points = [for (final p in glyph.strokes[i].points) _scalePoint(p, size)];
      if (points.isEmpty) continue;
      _drawDashedPolyline(canvas, points, guidePaint);
      final isNext = i == nextStrokeIndex;
      final radius = isNext ? 13.0 + 8 * blinkValue : 13.0;
      canvas.drawCircle(points.first, radius, startDotPaint);
      if (points.length >= 2) {
        _drawArrowHead(canvas, points[points.length - 2], points.last, arrowPaint);
      }
    }
  }

  void _paintStrokePoints(
    Canvas canvas,
    Size size,
    List<List<Offset>> strokes, {
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()..color = color;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(_scaleOffset(stroke.first, size), 8, dotPaint);
        continue;
      }
      final first = _scaleOffset(stroke.first, size);
      final path = Path()..moveTo(first.dx, first.dy);
      for (final point in stroke.skip(1)) {
        final scaled = _scaleOffset(point, size);
        path.lineTo(scaled.dx, scaled.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  /// Walks the whole polyline as one continuous dash+gap cycle, so the
  /// pattern stays consistent across the segments between key points
  /// instead of restarting (and looking uneven) at each one.
  void _drawDashedPolyline(
    Canvas canvas,
    List<Offset> points,
    Paint paint, {
    double dashLength = 14,
    double gapLength = 10,
  }) {
    if (points.length < 2) return;
    final cycle = dashLength + gapLength;
    var distanceIntoPattern = 0.0;

    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      var remaining = (end - start).distance;
      if (remaining == 0) continue;
      final direction = (end - start) / remaining;
      var current = start;

      while (remaining > 0) {
        final cyclePos = distanceIntoPattern % cycle;
        final isDash = cyclePos < dashLength;
        final distanceToToggle = isDash ? (dashLength - cyclePos) : (cycle - cyclePos);
        final step = distanceToToggle < remaining ? distanceToToggle : remaining;
        final next = current + direction * step;
        if (isDash) {
          canvas.drawLine(current, next, paint);
        }
        current = next;
        remaining -= step;
        distanceIntoPattern += step;
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint, {double size = 16}) {
    final direction = to - from;
    final length = direction.distance;
    if (length == 0) return;
    final unit = direction / length;
    final normal = Offset(-unit.dy, unit.dx);
    final left = to - unit * size + normal * (size * 0.55);
    final right = to - unit * size - normal * (size * 0.55);
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TracingCanvasPainter oldDelegate) {
    return oldDelegate.glyph != glyph ||
        oldDelegate.completedStrokes != completedStrokes ||
        oldDelegate.currentStrokePoints != currentStrokePoints ||
        oldDelegate.success != success ||
        oldDelegate.showGuide != showGuide ||
        oldDelegate.nextStrokeIndex != nextStrokeIndex ||
        oldDelegate.blinkValue != blinkValue ||
        oldDelegate.replayStrokeIndex != replayStrokeIndex ||
        oldDelegate.replayProgress != replayProgress;
  }
}
