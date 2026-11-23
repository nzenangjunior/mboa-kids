import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../core/tracing/tracing_glyph.dart';

/// Draws the dotted letter guide (with a start dot and a direction arrow
/// per stroke, CLAUDE.md section 10) and the child's own finger-drawn
/// strokes on top of it.
class TracingCanvasPainter extends CustomPainter {
  TracingCanvasPainter({
    required this.glyph,
    required this.drawnStrokes,
    required this.success,
  });

  final TracingGlyph glyph;

  /// One list of normalized (0..1) points per continuous finger gesture.
  final List<List<Offset>> drawnStrokes;

  final bool success;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGuide(canvas, size);
    _paintDrawnStrokes(canvas, size);
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

    for (final stroke in glyph.strokes) {
      final points = [for (final p in stroke.points) _scalePoint(p, size)];
      if (points.isEmpty) continue;
      _drawDashedPolyline(canvas, points, guidePaint);
      canvas.drawCircle(points.first, 13, startDotPaint);
      if (points.length >= 2) {
        _drawArrowHead(canvas, points[points.length - 2], points.last, arrowPaint);
      }
    }
  }

  void _paintDrawnStrokes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = success ? Colors.green.shade600 : MboaKidsTheme.pink
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()..color = paint.color;

    for (final stroke in drawnStrokes) {
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
        oldDelegate.drawnStrokes != drawnStrokes ||
        oldDelegate.success != success;
  }
}
