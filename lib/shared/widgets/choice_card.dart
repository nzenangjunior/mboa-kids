import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

enum ChoiceCardState { normal, correct, incorrect }

/// One of the big tappable answer tiles used across the games (alphabet,
/// numbers, vocabulary). Always at least [MboaKidsTheme.minTapTarget]
/// (CLAUDE.md section 2.4: touch targets >= 64 dp, max 3 choices).
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final ChoiceCardState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    switch (state) {
      case ChoiceCardState.normal:
        background = Colors.white;
      case ChoiceCardState.correct:
        background = Colors.green.shade300;
      case ChoiceCardState.incorrect:
        background = Colors.red.shade200;
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: MboaKidsTheme.purple,
            ),
          ),
        ),
      ),
    );
  }
}
