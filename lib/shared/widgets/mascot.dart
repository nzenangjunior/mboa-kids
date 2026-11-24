import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The four moods the mascot can show (CLAUDE.md section 10, Refonte
/// visuelle). Driven by game/screen state — see call sites for how each
/// is chosen (correct answer → [happy], wrong answer → [thinking], the
/// session ending early → [asleep]).
enum MascotMood { idle, happy, thinking, asleep }

/// The African grey parrot mascot, in one place so its look can later be
/// swapped for a professional illustration (SVG or a Lottie animation)
/// without touching any screen: every screen only ever depends on this
/// widget's `mood`/`onTap`/`size` interface, never on how it is drawn.
///
/// Touching it (when [onTap] is set) replays the current screen's voice
/// instruction (CLAUDE.md section 2.3: no text for the child to read).
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.mood = MascotMood.idle, this.onTap, this.size = 120});

  final MascotMood mood;
  final VoidCallback? onTap;
  final double size;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        size: Size.square(widget.size),
        painter: _ParrotPainter(mood: widget.mood, t: _controller.value),
      ),
    );

    if (widget.onTap == null) return content;

    return Semantics(
      button: true,
      label: 'Rejouer la consigne',
      child: GestureDetector(onTap: widget.onTap, child: content),
    );
  }
}

class _ParrotPainter extends CustomPainter {
  _ParrotPainter({required this.mood, required this.t});

  final MascotMood mood;

  /// 0..1, looping continuously — each mood reads whatever part of the
  /// cycle it needs (a bob, a wing flap, an occasional blink).
  final double t;

  static const _grey = Color(0xFFADA8B6);
  static const _darkGrey = Color(0xFF6E6877);
  static const _facePatch = Color(0xFFF2F0F5);
  static const _beak = Color(0xFF4A4550);
  static const _tailRed = Color(0xFFE0514B);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final s = size.width;
    final angle = t * 2 * math.pi;

    final bobAmplitude = switch (mood) {
      MascotMood.idle => s * 0.015,
      MascotMood.happy => s * 0.03,
      MascotMood.thinking => s * 0.006,
      MascotMood.asleep => s * 0.02,
    };
    final bobSpeed = mood == MascotMood.asleep ? 0.5 : (mood == MascotMood.happy ? 2.0 : 1.0);
    final bob = math.sin(angle * bobSpeed).abs() * bobAmplitude;

    canvas.save();
    canvas.translate(0, -bob);

    _paintTail(canvas, cx, s);
    _paintBody(canvas, cx, s);
    _paintWings(canvas, cx, s, angle);
    _paintHead(canvas, cx, s, angle);

    canvas.restore();
  }

  void _paintTail(Canvas canvas, double cx, double s) {
    final paint = Paint()..color = _tailRed;
    final feathers = [
      Offset(cx - s * 0.20, s * 0.95),
      Offset(cx, s * 0.99),
      Offset(cx + s * 0.20, s * 0.95),
    ];
    for (final tip in feathers) {
      final path = Path()
        ..moveTo(cx, s * 0.64)
        ..quadraticBezierTo(tip.dx - s * 0.05, s * 0.90, tip.dx, tip.dy)
        ..quadraticBezierTo(tip.dx + s * 0.05, s * 0.90, cx, s * 0.64)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _paintBody(Canvas canvas, double cx, double s) {
    final rect = Rect.fromCenter(center: Offset(cx, s * 0.70), width: s * 0.44, height: s * 0.30);
    final paint = Paint()..color = _grey;
    canvas.drawOval(rect, paint);
    canvas.drawOval(
      rect,
      Paint()
        ..color = _darkGrey.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012,
    );
  }

  void _paintWings(Canvas canvas, double cx, double s, double angle) {
    final flap = mood == MascotMood.happy ? math.sin(angle * 2) * 0.4 : -0.1;
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(cx + side * s * 0.32, s * 0.66);
      canvas.rotate(side * (0.35 + flap));
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: s * 0.16, height: s * 0.30),
        Paint()..color = _darkGrey,
      );
      canvas.restore();
    }
  }

  void _paintHead(Canvas canvas, double cx, double s, double angle) {
    final tilt = mood == MascotMood.thinking ? -0.22 + math.sin(angle * 0.5) * 0.02 : 0.0;
    final headCenter = Offset(cx, s * 0.34);

    canvas.save();
    canvas.translate(headCenter.dx, headCenter.dy);
    canvas.rotate(tilt);
    canvas.translate(-headCenter.dx, -headCenter.dy);

    canvas.drawCircle(headCenter, s * 0.30, Paint()..color = _grey);
    canvas.drawCircle(
      headCenter,
      s * 0.30,
      Paint()
        ..color = _darkGrey.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, s * 0.37), width: s * 0.40, height: s * 0.30),
      Paint()..color = _facePatch,
    );
    _paintBeak(canvas, cx, s);
    _paintEyes(canvas, cx, s, angle);

    canvas.restore();
  }

  void _paintBeak(Canvas canvas, double cx, double s) {
    final path = Path()
      ..moveTo(cx - s * 0.075, s * 0.42)
      ..quadraticBezierTo(cx, s * 0.37, cx + s * 0.085, s * 0.425)
      ..quadraticBezierTo(cx + s * 0.03, s * 0.50, cx - s * 0.025, s * 0.47)
      ..close();
    canvas.drawPath(path, Paint()..color = _beak);
  }

  void _paintEyes(Canvas canvas, double cx, double s, double angle) {
    final closed = mood == MascotMood.asleep;
    final blinking = !closed && mood == MascotMood.idle && (t % 1.0) > 0.93;
    final scale = mood == MascotMood.happy ? 1.15 : 1.0;
    final eyeY = s * 0.30;
    final eyeDx = s * 0.115;
    final eyeRadius = s * 0.09 * scale;

    for (final side in [-1.0, 1.0]) {
      final center = Offset(cx + side * eyeDx, eyeY);
      if (closed || blinking) {
        final path = Path()
          ..moveTo(center.dx - eyeRadius, center.dy)
          ..quadraticBezierTo(center.dx, center.dy + eyeRadius * 0.6, center.dx + eyeRadius, center.dy);
        canvas.drawPath(
          path,
          Paint()
            ..color = _darkGrey
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.014
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawCircle(center, eyeRadius, Paint()..color = Colors.white);
        canvas.drawCircle(center, eyeRadius * 0.62, Paint()..color = const Color(0xFF2A2730));
        canvas.drawCircle(
          Offset(center.dx - eyeRadius * 0.22, center.dy - eyeRadius * 0.22),
          eyeRadius * 0.22,
          Paint()..color = Colors.white,
        );
      }
      if (mood == MascotMood.thinking && side == 1.0) {
        canvas.drawLine(
          Offset(center.dx - eyeRadius, center.dy - eyeRadius * 1.6),
          Offset(center.dx + eyeRadius, center.dy - eyeRadius * 1.9),
          Paint()
            ..color = _darkGrey
            ..strokeWidth = s * 0.012
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    if (mood == MascotMood.asleep) {
      _paintSleepSpiral(canvas, cx + s * 0.32, s * 0.10, s, angle);
    }
  }

  void _paintSleepSpiral(Canvas canvas, double x, double y, double s, double angle) {
    final paint = Paint()
      ..color = _darkGrey.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle * 0.3);
    for (var i = 0; i < 2; i++) {
      final radius = s * (0.03 + i * 0.025);
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: radius), 0.3, 4.5, false, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ParrotPainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.t != t;
}
