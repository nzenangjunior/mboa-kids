import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

/// Touching the mascot replays the current screen's audio instruction.
/// Every child-facing screen needs this (CLAUDE.md section 2.3: no text
/// for the child to read, so the instruction must be replayable by touch).
class MascotTapTarget extends StatelessWidget {
  const MascotTapTarget({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Rejouer la consigne',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: MboaKidsTheme.pink,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.volume_up, size: 48, color: Colors.white),
        ),
      ),
    );
  }
}
