import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/audio/audio_service.dart';
import '../../core/rewards/intensity_level.dart';
import '../../core/rewards/star_rating.dart';
import '../../core/rewards/sticker_catalog.dart';
import '../../core/tracing/tracing_glyph.dart';
import '../../core/tracing/tracing_matcher.dart';
import '../../core/tracing/tracing_queue.dart';
import '../../shared/widgets/mascot_tap_target.dart';
import '../rewards/bravo_result.dart';
import 'tracing_canvas_painter.dart';

const _minDistanceBetweenPoints = 0.012;
const _successAdvanceDelay = Duration(milliseconds: 1600);
const _replayDuration = Duration(milliseconds: 1400);

/// The two passes every letter/number goes through (CLAUDE.md section 10):
/// first with the dotted guide, then again from memory to reinforce it.
enum _TracingStage { guided, unguided }

/// Finger-tracing activity (CLAUDE.md section 10, step 6): a dotted guide
/// with a start dot and a direction arrow per stroke, wide-tolerance
/// matching so a 4-year-old's finger can succeed, and no punishment for a
/// miss — a failed attempt just replays the stroke and the child keeps
/// drawing until it's good enough. Only already-recognized letters are
/// offered, except the first name, which is always traceable; numbers 1-5
/// are offered unconditionally for now (no numbers game exists yet to
/// gate them the same way). Each item is traced once with the guide, then
/// once more without it; a successful pass is recorded in the shared
/// per-item progression (the same one the recognition games use) and the
/// activity ends with stars and a sticker, exactly like the alphabet game.
class TracingGameScreen extends ConsumerStatefulWidget {
  const TracingGameScreen({super.key});

  @override
  ConsumerState<TracingGameScreen> createState() => _TracingGameScreenState();
}

class _TracingGameScreenState extends ConsumerState<TracingGameScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();

  List<TracingQueueItem>? _queue;
  TracingContent? _tracingContent;
  int _index = 0;
  bool _loading = true;
  bool _success = false;
  bool _finished = false;
  bool _replaying = false;
  _TracingStage _stage = _TracingStage.guided;

  bool _itemHadFailedAttempt = false;
  DateTime? _itemStartFirstAcquiredAt;
  int _tracedFirstTryCount = 0;
  final List<String> _newlyAcquiredGlyphs = [];

  final List<List<Offset>> _drawnStrokes = [];

  Timer? _advanceTimer;
  late final ConfettiController _confetti;
  late final AnimationController _replayController;

  /// Cached the first time it resolves, so [dispose] can stop it without
  /// touching `ref` (Riverpod forbids `ref.read` once a widget is being
  /// unmounted — see the alphabet game screen for the same pattern and the
  /// bug it fixes).
  AudioService? _audio;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _replayController = AnimationController(vsync: this, duration: _replayDuration)
      ..addStatusListener(_onReplayStatusChanged);
    _load();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _confetti.dispose();
    _replayController.dispose();
    unawaited(_audio?.stop());
    super.dispose();
  }

  void _onReplayStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _replaying = false);
    }
  }

  Future<void> _load() async {
    final world = ref.read(worldProvider);
    final tracingContent = await ref.read(tracingContentProvider.future);
    final alphabet = await ref.read(alphabetContentProvider(world).future);
    final numbers = await ref.read(numbersContentProvider(world).future);
    final repository = ref.read(progressRepositoryProvider);
    final states = await repository.statesFor(
      alphabet.items.map((item) => item.id).toList(),
    );
    final firstName = ref.read(childFirstNameProvider);

    final queue = buildFullTracingQueue(
      alphabetItems: alphabet.items,
      states: states,
      firstName: firstName,
      numbersContent: numbers,
      hasTracingData: (glyphKey) => tracingContent[glyphKey] != null,
    );

    if (!mounted) return;
    setState(() {
      _tracingContent = tracingContent;
      _queue = queue;
      _loading = false;
      _finished = queue.isEmpty;
    });
    if (queue.isNotEmpty) {
      unawaited(_prepareAndPromptCurrentItem());
    }
  }

  Future<AudioService> _audioFor(String world) async {
    final audio = await ref.read(audioServiceProvider(world).future);
    _audio = audio;
    return audio;
  }

  /// Captures the item's progress snapshot before this attempt (to detect
  /// a newly-`acquis` item later) and speaks the prompt for it.
  Future<void> _prepareAndPromptCurrentItem() async {
    final item = _queue![_index];
    try {
      final repository = ref.read(progressRepositoryProvider);
      final snapshot = await repository.snapshotFor(item.id);
      _itemStartFirstAcquiredAt = snapshot.firstAcquiredAt;
    } catch (_) {
      _itemStartFirstAcquiredAt = null;
    }
    await _playPromptForCurrent();
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
    if (_success || _replaying || box.width == 0 || box.height == 0) return;
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
    if (_success || _replaying) return;
    final glyph = _tracingContent![_queue![_index].glyphKey];
    if (glyph == null) return;
    final allPoints = [for (final stroke in _drawnStrokes) ...stroke];
    final tolerance = ref.read(tracingToleranceProvider);
    if (!isGoodTrace(glyph: glyph, drawnPoints: allPoints, tolerance: tolerance)) {
      _startReplay();
      return;
    }

    setState(() => _success = true);
    unawaited(_playSuccessAudio());
    _advanceTimer?.cancel();
    _advanceTimer = Timer(_successAdvanceDelay, _onStageSucceeded);
  }

  /// A failed attempt is never a punishment (CLAUDE.md rule 5): the guide
  /// (shown even in "sans guide" mode, just for this demo) plays a
  /// traveling marker along the stroke and the prompt is replayed, then
  /// the child simply tries again.
  void _startReplay() {
    _itemHadFailedAttempt = true;
    setState(() {
      _replaying = true;
      _drawnStrokes.clear();
    });
    unawaited(_playPromptForCurrent());
    _replayController
      ..reset()
      ..forward();
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

  void _onStageSucceeded() {
    if (!mounted) return;
    if (_stage == _TracingStage.guided) {
      setState(() {
        _stage = _TracingStage.unguided;
        _success = false;
        _drawnStrokes.clear();
      });
      unawaited(_playPromptForCurrent());
      return;
    }
    unawaited(_recordItemCompleted());
  }

  /// The unguided pass just succeeded: this item is fully done. Recorded
  /// in the same per-item progression the recognition games use (CLAUDE.md
  /// section 10: "comme le jeu de l'alphabet").
  Future<void> _recordItemCompleted() async {
    final item = _queue![_index];
    final firstTry = !_itemHadFailedAttempt;
    try {
      final repository = ref.read(progressRepositoryProvider);
      final updated = await repository.recordAnswer(
        itemId: item.id,
        correct: true,
        firstTry: firstTry,
        today: ref.read(engineClockProvider)(),
      );
      if (firstTry) _tracedFirstTryCount++;
      if (_itemStartFirstAcquiredAt == null && updated.firstAcquiredAt != null) {
        _newlyAcquiredGlyphs.add(item.glyphKey);
      }
    } catch (_) {
      // Recording failing must never block the activity from moving on.
    }
    _goToNextQueueItem();
  }

  void _goToNextQueueItem() {
    if (!mounted) return;
    if (_index + 1 >= _queue!.length) {
      setState(() => _finished = true);
      unawaited(_finishActivity());
      return;
    }
    setState(() {
      _index++;
      _stage = _TracingStage.guided;
      _success = false;
      _itemHadFailedAttempt = false;
      _drawnStrokes.clear();
    });
    unawaited(_prepareAndPromptCurrentItem());
  }

  /// How long to wait on the sticker catalog and the database write
  /// before giving up on them (mirrors the alphabet game's same timeout
  /// and the same reasoning: finishing matters more than waiting
  /// indefinitely on either, CLAUDE.md section 13).
  static const _finishActivityStepTimeout = Duration(seconds: 4);
  static const _fallbackSticker = GameSticker(id: 'sticker.fallback', emoji: '⭐');

  Future<void> _finishActivity() async {
    final intensity = await ref.read(intensityProvider.future);
    if (intensity != IntensityLevel.calme) {
      _confetti.play();
    }

    final repository = ref.read(progressRepositoryProvider);
    var sticker = _fallbackSticker;
    try {
      final catalog = await ref
          .read(stickerCatalogListProvider.future)
          .timeout(_finishActivityStepTimeout);
      sticker = pickRandomSticker(catalog, _random);
      await repository
          .recordStickerEarned(sticker.id, ref.read(engineClockProvider)())
          .timeout(_finishActivityStepTimeout);
    } on TimeoutException catch (error) {
      // Keep the built-in sticker and move on: see CLAUDE.md section 13,
      // this must never leave the end of the activity stuck.
      debugPrint(
        '[tracing] _finishActivityStepTimeout (${_finishActivityStepTimeout.inSeconds}s) '
        'fired: $error',
      );
    } catch (_) {
      // Keep the built-in sticker and move on regardless of what failed.
    }

    if (!mounted) return;
    context.go(
      '/bravo',
      extra: BravoResult(
        stars: starsForTracingFirstTry(_tracedFirstTryCount, _queue!.length),
        gameSticker: sticker,
        newlyAcquiredLetterGlyphs: _newlyAcquiredGlyphs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_finished) {
      return _buildEmptyQueue(context);
    }

    final item = _queue![_index];
    final glyph = _tracingContent![item.glyphKey];

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
                                  child: AnimatedBuilder(
                                    animation: _replayController,
                                    builder: (context, _) => CustomPaint(
                                      size: box,
                                      painter: TracingCanvasPainter(
                                        glyph: glyph,
                                        drawnStrokes: _drawnStrokes,
                                        success: _success,
                                        showGuide: _stage == _TracingStage.guided,
                                        replayProgress:
                                            _replaying ? _replayController.value : null,
                                      ),
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

  /// Nothing is eligible yet (e.g. a brand-new profile with no first name
  /// and no recognized letters). Not a real completion, so it goes
  /// straight home rather than through the Bravo screen.
  Widget _buildEmptyQueue(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/'),
          child: const Text('Accueil', style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
