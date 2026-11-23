import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/audio/audio_service.dart';
import '../../core/content/models/alphabet_item.dart';
import '../../core/rewards/intensity_level.dart';
import '../../core/tracing/tracing_glyph.dart';
import '../../core/tracing/tracing_matcher.dart';
import '../../core/tracing/tracing_queue.dart';
import '../../shared/widgets/mascot_tap_target.dart';
import 'tracing_canvas_painter.dart';

const _minDistanceBetweenPoints = 0.012;
const _successAdvanceDelay = Duration(milliseconds: 1600);

/// Finger-tracing activity (CLAUDE.md section 10, step 6): a dotted guide
/// with a start dot and a direction arrow per stroke, wide-tolerance
/// matching so a 4-year-old's finger can succeed, and no punishment for a
/// miss — the child just keeps drawing until it's good enough. Only
/// already-recognized letters are offered, except the first name, which is
/// always traceable (CLAUDE.md section 7).
class TracingGameScreen extends ConsumerStatefulWidget {
  const TracingGameScreen({super.key});

  @override
  ConsumerState<TracingGameScreen> createState() => _TracingGameScreenState();
}

class _TracingGameScreenState extends ConsumerState<TracingGameScreen> {
  List<AlphabetItem>? _queue;
  TracingContent? _tracingContent;
  int _index = 0;
  bool _loading = true;
  bool _success = false;
  bool _finished = false;

  final List<List<Offset>> _drawnStrokes = [];

  Timer? _advanceTimer;
  late final ConfettiController _confetti;

  /// Cached the first time it resolves, so [dispose] can stop it without
  /// touching `ref` (Riverpod forbids `ref.read` once a widget is being
  /// unmounted — see the alphabet game screen for the same pattern and the
  /// bug it fixes).
  AudioService? _audio;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _load();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _confetti.dispose();
    unawaited(_audio?.stop());
    super.dispose();
  }

  Future<void> _load() async {
    final world = ref.read(worldProvider);
    final tracingContent = await ref.read(tracingContentProvider.future);
    final alphabet = await ref.read(alphabetContentProvider(world).future);
    final repository = ref.read(progressRepositoryProvider);
    final states = await repository.statesFor(
      alphabet.items.map((item) => item.id).toList(),
    );
    final firstName = ref.read(childFirstNameProvider);

    final queue = buildTracingQueue(
      alphabetItems: alphabet.items,
      states: states,
      firstName: firstName,
      hasTracingData: (glyph) => tracingContent[glyph] != null,
    );

    if (!mounted) return;
    setState(() {
      _tracingContent = tracingContent;
      _queue = queue;
      _loading = false;
      _finished = queue.isEmpty;
    });
    if (queue.isNotEmpty) {
      unawaited(_playPromptForCurrent());
    }
  }

  Future<AudioService> _audioFor(String world) async {
    final audio = await ref.read(audioServiceProvider(world).future);
    _audio = audio;
    return audio;
  }

  Future<void> _playPromptForCurrent() async {
    try {
      final world = ref.read(worldProvider);
      final audio = await _audioFor(world);
      await audio.playPrompt('trace_the_letter');
      await audio.playItem(_queue![_index].id);
    } catch (_) {
      // A missing or slow clip must never block the activity: the child
      // can still see the guide and trace it without the spoken prompt.
    }
  }

  void _addPoint(Offset localPosition, Size box, {required bool newStroke}) {
    if (_success || box.width == 0 || box.height == 0) return;
    final normalized = Offset(
      (localPosition.dx / box.width).clamp(0.0, 1.0),
      (localPosition.dy / box.height).clamp(0.0, 1.0),
    );
    setState(() {
      if (newStroke || _drawnStrokes.isEmpty) {
        _drawnStrokes.add([normalized]);
        return;
      }
      final current = _drawnStrokes.last;
      if (current.isEmpty ||
          (current.last - normalized).distance > _minDistanceBetweenPoints) {
        current.add(normalized);
      }
    });
  }

  void _onPanEnd() {
    if (_success) return;
    final glyph = _tracingContent![_queue![_index].glyph];
    if (glyph == null) return;
    final allPoints = [for (final stroke in _drawnStrokes) ...stroke];
    if (!isGoodTrace(glyph: glyph, drawnPoints: allPoints)) return;

    setState(() => _success = true);
    unawaited(_playSuccessAudio());
    _advanceTimer?.cancel();
    _advanceTimer = Timer(_successAdvanceDelay, _goToNext);
  }

  Future<void> _playSuccessAudio() async {
    try {
      final world = ref.read(worldProvider);
      final audio = await _audioFor(world);
      await audio.playSfx('success_chime');
      await audio.playPraise();
    } catch (_) {
      // Playback failing must never affect the activity: the timer above
      // already controls when it moves on, independently of this.
    }
  }

  void _goToNext() {
    if (!mounted) return;
    if (_index + 1 >= _queue!.length) {
      setState(() => _finished = true);
      unawaited(_playFinishedAudio());
      return;
    }
    setState(() {
      _index++;
      _success = false;
      _drawnStrokes.clear();
    });
    unawaited(_playPromptForCurrent());
  }

  Future<void> _playFinishedAudio() async {
    final intensity = await ref.read(intensityProvider.future);
    if (intensity != IntensityLevel.calme) {
      _confetti.play();
    }
    try {
      final world = ref.read(worldProvider);
      final audio = await _audioFor(world);
      await audio.playPraise();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_finished) {
      return _buildFinished(context);
    }

    final item = _queue![_index];
    final glyph = _tracingContent![item.glyph];

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MascotTapTarget(onTap: _playPromptForCurrent),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: MboaKidsTheme.lightPurple, width: 3),
                      ),
                      child: glyph == null
                          ? const SizedBox.shrink()
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final box = constraints.biggest;
                                return GestureDetector(
                                  onPanStart: (details) => _addPoint(
                                    details.localPosition,
                                    box,
                                    newStroke: true,
                                  ),
                                  onPanUpdate: (details) => _addPoint(
                                    details.localPosition,
                                    box,
                                    newStroke: false,
                                  ),
                                  onPanEnd: (_) => _onPanEnd(),
                                  child: CustomPaint(
                                    size: box,
                                    painter: TracingCanvasPainter(
                                      glyph: glyph,
                                      drawnStrokes: _drawnStrokes,
                                      success: _success,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinished(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: MboaKidsTheme.pink, size: 96),
                const SizedBox(height: 32),
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
