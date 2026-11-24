import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

/// How far through the current game/session the child is (CLAUDE.md
/// section 10, Refonte visuelle: "barre de progression de la partie").
/// [total] is the real number of questions/traces in this session, never
/// hardcoded — a level-scoped session can be shorter than the usual 5.
class ProgressDots extends StatelessWidget {
  const ProgressDots({super.key, required this.total, required this.filled});

  final int total;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? MboaKidsTheme.pink : MboaKidsTheme.lightPurple,
              ),
            ),
          ),
      ],
    );
  }
}
