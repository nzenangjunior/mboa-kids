import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
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
///
/// A step indicator (lettres → tracé → étoile) is shown big and announced
/// for the first 2s, then stays small at the top for the rest of the
/// path, with a short transition announced between the alphabet and
/// tracing steps (CLAUDE.md section 10, Refonte visuelle).
class DailyPathScreen extends ConsumerStatefulWidget {
  const DailyPathScreen({super.key});

  @override
  ConsumerState<DailyPathScreen> createState() => _DailyPathScreenState();
}

class _DailyPathScreenState extends ConsumerState<DailyPathScreen> {
  _DailyPathPhase _phase = _DailyPathPhase.alphabet;
  BravoResult? _alphabetResult;
  late final DateTime _startedAt;

  bool _showIntro = true;
  bool _showTransition = false;
  Timer? _introTimer;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    _startedAt = ref.read(engineClockProvider)();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPrompt('daily_path_intro'));
    _introTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showIntro = false);
    });
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _transitionTimer?.cancel();
    super.dispose();
  }

  Future<void> _playPrompt(String key) async {
    try {
      final world = ref.read(worldProvider);
      final audio = await ref.read(audioServiceProvider(world).future);
      await audio.playPrompt(key);
    } catch (_) {}
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
    setState(() {
      _phase = _DailyPathPhase.tracing;
      _showTransition = true;
    });
    unawaited(_playPrompt('daily_path_to_tracing'));
    _transitionTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showTransition = false);
    });
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
    final currentStep = switch (_phase) {
      _DailyPathPhase.alphabet => _Step.alphabet,
      _DailyPathPhase.tracing => _Step.tracing,
    };

    return Stack(
      children: [
        switch (_phase) {
          _DailyPathPhase.alphabet => AlphabetGameScreen(onFinished: _onAlphabetFinished),
          _DailyPathPhase.tracing => TracingGameScreen(onFinished: _onTracingFinished),
        },
        if (_showIntro || _showTransition)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(child: _StepRow(currentStep: currentStep, big: true)),
            ),
          )
        else
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _StepRow(currentStep: currentStep, big: false),
              ),
            ),
          ),
      ],
    );
  }
}

enum _Step { alphabet, tracing, bravo }

const _stepIcons = {
  _Step.alphabet: Icons.abc,
  _Step.tracing: Icons.edit,
  _Step.bravo: Icons.star,
};

const _stepOrder = [_Step.alphabet, _Step.tracing, _Step.bravo];

class _StepRow extends StatelessWidget {
  const _StepRow({required this.currentStep, required this.big});

  final _Step currentStep;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _stepOrder.indexOf(currentStep);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: big ? 0 : 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: big ? 0 : 12, vertical: big ? 0 : 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _stepOrder.length; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: big ? 20 : 6),
                child: _StepIcon(
                  icon: _stepIcons[_stepOrder[i]]!,
                  big: big,
                  done: i < currentIndex,
                  current: i == currentIndex,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({
    required this.icon,
    required this.big,
    required this.done,
    required this.current,
  });

  final IconData icon;
  final bool big;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final size = big ? 72.0 : 28.0;
    final color = done
        ? Colors.green.shade400
        : (current ? MboaKidsTheme.pink : Colors.grey.shade400);

    return Container(
      width: size + 16,
      height: size + 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: current ? Border.all(color: color, width: 3) : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: size, color: big ? Colors.white : color),
          if (done)
            Positioned(
              bottom: 0,
              right: 0,
              child: Icon(Icons.check_circle, size: size * 0.4, color: Colors.green.shade600),
            ),
        ],
      ),
    );
  }
}
