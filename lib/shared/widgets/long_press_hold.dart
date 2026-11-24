import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Fires [onHeld] only after the finger stays down for [duration] — unlike
/// `GestureDetector.onLongPress` (a fixed, short system duration), so a
/// discreet control can require a deliberate hold instead of an
/// accidental tap (CLAUDE.md section 10, Refonte visuelle: "cadenas
/// parent... accessible seulement par un appui long de 2 secondes").
class LongPressHold extends StatefulWidget {
  const LongPressHold({
    super.key,
    required this.onHeld,
    required this.child,
    this.duration = const Duration(seconds: 2),
  });

  final VoidCallback onHeld;
  final Widget child;
  final Duration duration;

  @override
  State<LongPressHold> createState() => _LongPressHoldState();
}

class _LongPressHoldState extends State<LongPressHold> {
  Timer? _timer;

  void _start() {
    _timer?.cancel();
    _timer = Timer(widget.duration, widget.onHeld);
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _cancel(),
      onTapCancel: _cancel,
      child: widget.child,
    );
  }
}
