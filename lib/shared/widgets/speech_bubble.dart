import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

/// A speech bubble shown above the mascot while it is talking (CLAUDE.md
/// section 10, Refonte visuelle: "une bulle quand il parle"). No text
/// inside — just a little sound-wave icon, consistent with "aucun texte
/// à lire pour l'enfant".
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: AnimatedScale(
        scale: visible ? 1 : 0.6,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: CustomPaint(
          painter: _BubblePainter(),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Icon(Icons.graphic_eq, color: MboaKidsTheme.purple, size: 28),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.75),
      const Radius.circular(18),
    );
    canvas.drawRRect(body, paint);

    final tail = Path()
      ..moveTo(size.width * 0.38, size.height * 0.72)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.58, size.height * 0.72)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => false;
}
