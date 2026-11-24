import 'package:material_ui/material_ui.dart';

/// A discreet geometric motif inspired by pagne/ndop fabric, used as a
/// faint background layer (CLAUDE.md section 10, Refonte visuelle:
/// "fond de motifs discrets inspirés du pagne/ndop"). Low opacity, wide
/// spacing, and a single lightweight painter: meant to add warmth behind
/// a scene without competing with it or costing anything on entry-level
/// hardware.
class PagnePattern extends StatelessWidget {
  const PagnePattern({super.key, this.color = Colors.white, this.opacity = 0.08});

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _PagnePainter(color: color.withValues(alpha: opacity)),
      ),
    );
  }
}

class _PagnePainter extends CustomPainter {
  _PagnePainter({required this.color});

  final Color color;

  static const _cell = 56.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var y = -_cell; y < size.height + _cell; y += _cell) {
      for (var x = -_cell; x < size.width + _cell; x += _cell) {
        final offsetX = x + ((y ~/ _cell).isOdd ? _cell / 2 : 0);
        final center = Offset(offsetX, y + _cell / 2);
        final path = Path()
          ..moveTo(center.dx, center.dy - _cell * 0.32)
          ..lineTo(center.dx + _cell * 0.32, center.dy)
          ..lineTo(center.dx, center.dy + _cell * 0.32)
          ..lineTo(center.dx - _cell * 0.32, center.dy)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawCircle(center, 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PagnePainter oldDelegate) => oldDelegate.color != color;
}
