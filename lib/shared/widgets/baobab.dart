import 'package:material_ui/material_ui.dart';

/// A simple baobab silhouette for the home scene (CLAUDE.md section 10,
/// Refonte visuelle: "le baobab bouge" when touched), drawn with plain
/// shapes — no downloaded image.
class Baobab extends StatefulWidget {
  const Baobab({super.key, this.onTap, this.height = 220});

  final VoidCallback? onTap;
  final double height;

  @override
  State<Baobab> createState() => _BaobabState();
}

class _BaobabState extends State<Baobab> with SingleTickerProviderStateMixin {
  late final AnimationController _sway;

  @override
  void initState() {
    super.initState();
    _sway = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  void _onTap() {
    _sway.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: 'Baobab',
      child: GestureDetector(
        onTap: widget.onTap == null ? null : _onTap,
        child: AnimatedBuilder(
          animation: _sway,
          builder: (context, child) {
            final angle = Curves.elasticOut.transform(_sway.value) * 0.06 * (1 - _sway.value);
            return Transform.rotate(
              alignment: Alignment.bottomCenter,
              angle: angle,
              child: child,
            );
          },
          child: CustomPaint(
            size: Size(widget.height * 0.8, widget.height),
            painter: _BaobabPainter(),
          ),
        ),
      ),
    );
  }
}

class _BaobabPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final trunkPaint = Paint()..color = const Color(0xFF8C6239);
    final canopyPaint = Paint()..color = const Color(0xFF6E8B4A);

    final trunk = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.72),
        width: size.width * 0.26,
        height: size.height * 0.5,
      ),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(trunk, trunkPaint);

    for (final branch in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + branch * size.width * 0.18, size.height * 0.46),
          width: size.width * 0.12,
          height: size.height * 0.22,
        ),
        trunkPaint,
      );
    }

    for (final layer in [
      (dx: 0.0, dy: 0.30, w: 0.95, h: 0.42),
      (dx: -0.22, dy: 0.22, w: 0.55, h: 0.3),
      (dx: 0.24, dy: 0.20, w: 0.5, h: 0.26),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + layer.dx * size.width, size.height * layer.dy),
          width: size.width * layer.w,
          height: size.height * layer.h,
        ),
        canopyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BaobabPainter oldDelegate) => false;
}
