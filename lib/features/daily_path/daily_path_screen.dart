import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../alphabet/alphabet_game_screen.dart';
import '../rewards/bravo_result.dart';
import '../tracing/tracing_game_screen.dart';

enum _DailyPathPhase { alphabet, tracing }

/// "Parcours du jour" (CLAUDE.md section 10): one alphabet game, then one
/// tracing session (capped at 5 traces), finishing on a single combined
/// Bravo screen. Stops early — straight to Bravo with whatever was
/// already earned, then the "mascotte dort" screen instead of a second
/// activity (CLAUDE.md section 7) — if the configured session duration
/// (10 min by default) is used up after the alphabet game.
class DailyPathScreen extends ConsumerStatefulWidget {
  const DailyPathScreen({super.key});

  @override
  ConsumerState<DailyPathScreen> createState() => _DailyPathScreenState();
}

class _DailyPathScreenState extends ConsumerState<DailyPathScreen> {
  _DailyPathPhase _phase = _DailyPathPhase.alphabet;
  BravoResult? _alphabetResult;
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = ref.read(engineClockProvider)();
  }

  bool get _durationExceeded {
    final duration = ref.read(sessionDurationProvider);
    final now = ref.read(engineClockProvider)();
    return now.difference(_startedAt) >= duration;
  }

  void _onAlphabetFinished(BravoResult result) {
    _alphabetResult = result;
    if (_durationExceeded) {
      ref.read(dailyPathSleepsAfterProvider.notifier).state = true;
      _finish(result);
      return;
    }
    setState(() => _phase = _DailyPathPhase.tracing);
  }

  void _onTracingFinished(BravoResult tracingResult) {
    final alphabetResult = _alphabetResult;
    if (alphabetResult == null) {
      _finish(tracingResult);
      return;
    }
    _finish(
      BravoResult(
        stars: ((alphabetResult.stars + tracingResult.stars) / 2).round().clamp(1, 3),
        gameSticker: tracingResult.gameSticker,
        newlyAcquiredLetterGlyphs: [
          ...alphabetResult.newlyAcquiredLetterGlyphs,
          ...tracingResult.newlyAcquiredLetterGlyphs,
        ],
      ),
    );
  }

  void _finish(BravoResult result) {
    if (!mounted) return;
    context.go('/bravo', extra: result);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _DailyPathPhase.alphabet:
        return AlphabetGameScreen(onFinished: _onAlphabetFinished);
      case _DailyPathPhase.tracing:
        return TracingGameScreen(onFinished: _onTracingFinished);
    }
  }
}
