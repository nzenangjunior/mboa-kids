import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/rewards/intensity_level.dart';
import 'bravo_result.dart';

/// End-of-game celebration (CLAUDE.md section 8): stars from how many
/// questions were answered correctly on the first try, a sticker for
/// finishing the game, and a golden sticker for every letter newly
/// `acquis` this game. Big effects (confetti) are reserved for this
/// screen — never a single question — and are skipped entirely in
/// "calme" intensity.
class BravoScreen extends ConsumerStatefulWidget {
  const BravoScreen({super.key, this.result});

  final BravoResult? result;

  @override
  ConsumerState<BravoScreen> createState() => _BravoScreenState();
}

class _BravoScreenState extends ConsumerState<BravoScreen> {
  late final ConfettiController _confetti;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;

    final intensity = await ref.read(intensityProvider.future);
    if (intensity != IntensityLevel.calme) {
      _confetti.play();
    }

    final world = ref.read(worldProvider);
    final audio = await ref.read(audioServiceProvider(world).future);
    await audio.playPraise();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (!_started) {
      _start();
    }

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (result != null) _StarRow(stars: result.stars),
                const SizedBox(height: 24),
                if (result != null)
                  Wrap(
                    spacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _GameStickerBadge(emoji: result.gameSticker.emoji),
                      for (final glyph in result.newlyAcquiredLetterGlyphs)
                        _GoldenLetterBadge(glyph: glyph),
                    ],
                  ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Accueil', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 24,
            maxBlastForce: 20,
            minBlastForce: 8,
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final filled = index < stars;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + index * 150),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: Icon(
            filled ? Icons.star : Icons.star_border,
            color: MboaKidsTheme.pink,
            size: 72,
          ),
        );
      }),
    );
  }
}

class _GameStickerBadge extends StatelessWidget {
  const _GameStickerBadge({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: MboaKidsTheme.lightPurple, width: 3),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 40)),
      ),
    );
  }
}

/// Rarer and more animated than [_GameStickerBadge]: a letter becoming
/// `acquis` matters more than just finishing a game.
class _GoldenLetterBadge extends StatefulWidget {
  const _GoldenLetterBadge({required this.glyph});

  final String glyph;

  @override
  State<_GoldenLetterBadge> createState() => _GoldenLetterBadgeState();
}

class _GoldenLetterBadgeState extends State<_GoldenLetterBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = Curves.elasticOut.transform(_controller.value);
        final turns = (1 - _controller.value) * 0.5;
        return Transform.rotate(
          angle: turns * 6.28,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: 88,
        height: 88,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x55FFA500), blurRadius: 12)],
        ),
        child: Text(
          widget.glyph,
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
