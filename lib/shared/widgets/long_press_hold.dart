import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Fires [onHeld] only after the finger stays down for [duration] — unlike
/// `GestureDetector.onLongPress` (a fixed, short system duration), so a
/// discreet control can require a deliberate hold instead of an
/// accidental tap (CLAUDE.md section 10, Refonte visuelle: "cadenas
/// parent... accessible seulement par un appui long de 2 secondes").
///
/// [builder] is handed the hold's progress (0..1 while held, animating
/// back to 0 if released early) so the control can show a filling ring —
/// otherwise a child has no way to know it must keep pressing. [onHeld]
/// itself is driven by a plain [Timer], not the animation's own status,
/// since an [AnimationController] reaching its end value does not reach
/// `AnimationStatus.completed` reliably on the same frame under
/// `flutter_test`'s fake clock — the ring is purely visual feedback.
class LongPressHold extends StatefulWidget {
  const LongPressHold({
    super.key,
    required this.onHeld,
    required this.builder,
    this.duration = const Duration(seconds: 2),
  });

  final VoidCallback onHeld;
  final Widget Function(BuildContext context, double progress) builder;
  final Duration duration;

  @override
  State<LongPressHold> createState() => _LongPressHoldState();
}

class _LongPressHoldState extends State<LongPressHold> with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  void _start() {
    _ringController.forward(from: 0);
    _timer?.cancel();
    _timer = Timer(widget.duration, widget.onHeld);
  }

  void _release() {
    _timer?.cancel();
    _timer = null;
    _ringController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      child: AnimatedBuilder(
        animation: _ringController,
        builder: (context, _) => widget.builder(context, _ringController.value),
      ),
    );
  }
}
