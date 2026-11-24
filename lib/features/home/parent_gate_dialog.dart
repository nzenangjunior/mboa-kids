import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

/// The calcul gate in front of anything parent-only (CLAUDE.md section 9),
/// shown after a 2-second long-press on the home screen's lock icon. A
/// correct answer resolves the dialog with `true`; a wrong one (or
/// dismissing it) resolves with `false` — the caller is expected to do
/// nothing more than close it in that case ("retour à l'accueil sans
/// message"), never show an error.
///
/// Uses 3 big answer choices rather than CLAUDE.md section 9's own
/// numeric-keypad wording: a deliberate, explicit choice for this
/// temporary stand-in (there is no parent space yet, étape 13) — update
/// section 9 together with the real parent gate once that's built, if a
/// keypad is still wanted then.
class ParentGateDialog extends StatefulWidget {
  const ParentGateDialog({super.key});

  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  late final int _a;
  late final int _b;
  late final List<int> _options;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _a = 3 + random.nextInt(7);
    _b = 3 + random.nextInt(7);
    final correct = _a + _b;

    final distractors = <int>{};
    while (distractors.length < 2) {
      final delta = 1 + random.nextInt(3);
      final candidate = random.nextBool() ? correct + delta : correct - delta;
      if (candidate > 0 && candidate != correct) distractors.add(candidate);
    }
    _options = [correct, ...distractors]..shuffle(random);
  }

  void _answer(int value) {
    Navigator.of(context).pop(value == _a + _b);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_a + $_b = ?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: MboaKidsTheme.purple,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in _options)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () => _answer(option),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(
                          MboaKidsTheme.minTapTarget,
                          MboaKidsTheme.minTapTarget,
                        ),
                      ),
                      child: Text('$option', style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
