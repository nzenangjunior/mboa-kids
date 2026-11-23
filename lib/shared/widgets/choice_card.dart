import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

enum ChoiceCardState { normal, correct, incorrect }

/// One of the big tappable answer tiles used across the games (alphabet,
/// numbers, vocabulary). Always at least [MboaKidsTheme.minTapTarget]
/// (CLAUDE.md section 2.4: touch targets >= 64 dp, max 3 choices).
class ChoiceCard extends StatefulWidget {
  const ChoiceCard({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    this.isHinted = false,
  });

  final String label;
  final ChoiceCardState state;
  final VoidCallback? onTap;

  /// "Mode aidé" (CLAUDE.md section 7): the correct answer glows gently
  /// before the child has tapped anything, after 2 consecutive mistakes.
  final bool isHinted;

  @override
  State<ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<ChoiceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.state == ChoiceCardState.incorrect) {
      _shakeController.forward();
    }
  }

  @override
  void didUpdateWidget(ChoiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == ChoiceCardState.incorrect &&
        oldWidget.state != ChoiceCardState.incorrect) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color background;
    switch (widget.state) {
      case ChoiceCardState.normal:
        background = widget.isHinted ? MboaKidsTheme.lightPink : Colors.white;
      case ChoiceCardState.correct:
        background = Colors.green.shade300;
      case ChoiceCardState.incorrect:
        background = Colors.red.shade200;
    }

    final isHintedNormal = widget.isHinted && widget.state == ChoiceCardState.normal;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final progress = _shakeController.value;
        final offset = sin(progress * pi * 6) * (1 - progress) * 8;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(24),
        elevation: isHintedNormal ? 8 : 4,
        shadowColor: widget.isHinted ? MboaKidsTheme.pink : null,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            decoration: isHintedNormal
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: MboaKidsTheme.pink, width: 3),
                  )
                : null,
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: MboaKidsTheme.purple,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
