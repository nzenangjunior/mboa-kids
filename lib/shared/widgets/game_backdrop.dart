import 'package:material_ui/material_ui.dart';

import 'pagne_pattern.dart';

/// A background decorated per island (CLAUDE.md section 10, Refonte
/// visuelle: "fond décoré selon l'île"), behind a game's own content.
class GameBackdrop extends StatelessWidget {
  const GameBackdrop({super.key, required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, accent.withValues(alpha: 0.18)],
              ),
            ),
          ),
        ),
        Positioned.fill(child: PagnePattern(color: accent)),
        child,
      ],
    );
  }
}
