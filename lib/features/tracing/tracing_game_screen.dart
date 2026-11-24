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
import '../../shared/widgets/game_backdrop.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/progress_dots.dart';
import '../rewards/bravo_result.dart';
import 'tracing_canvas_painter.dart';

const _minDistanceBetweenPoints = 0.012;
const _successAdvanceDelay = Duration(milliseconds: 1600);
const _replayDuration = Duration(milliseconds: 1400);

/// Finger-tracing activity (CLAUDE.md section 10, step 6): a dotted guide
/// with a start dot and a direction arrow per stroke, wide-tolerance
/// matching so a 4-year-old's finger can succeed, and no punishment for a
/// miss — a failed attempt just replays the stroke and the child keeps
/// drawing until it's good enough. Only already-recognized letters are
/// offered, except the first name, which is always traceable; numbers 1-5
/// are offered unconditionally for now (no numbers game exists yet to gate
/// them the same way).
///
/// At most [tracingMaxItemsPerSession] items are traced per session,
/// resuming after wherever the last session left off rather than
/// restarting from the first name every time — a name longer than that is
/// simply spelled out over several sessions.
///
/// Each item is shown with the dotted guide the first time; once it has
/// been successfully traced with the guide on an earlier day (never the
/// same session), it is offered without the guide instead, from memory.
/// A successful trace is recorded in the same per-item progression the
/// recognition games use, and the activity ends with stars and a sticker,
/// exactly like the alphabet game.
class TracingGameScreen extends ConsumerStatefulWidget {
  const TracingGameScreen({super.key, this.explicitItems, this.levelId, this.onFinished});

  /// When set, the session traces only these items (CLAUDE.md section 10:
  /// "1 niveau = 1 paquet" or the "prénom" level), reached by tapping that
  /// level on the island's path, instead of the automatic queue with its
  /// cross-session cursor and 5-item cap. [levelId] must be set too, to
  /// record that level's best stars.
  final List<TracingQueueItem>? explicitItems;
  final String? levelId;

  /// Called with the finished session's result instead of navigating to
  /// `/bravo` directly, so a caller such as the daily path can chain into
  /// another activity first and show one combined Bravo screen at the
  /// end. Defaults to navigating to `/bravo` itself, for standalone play.
  final void Function(BravoResult result)? onFinished;

  @override
  ConsumerState<TracingGameScreen> createState() => _TracingGameScreenState();
}

class _TracingGameScreenState extends ConsumerState<TracingGameScreen>
    with TickerProviderStateMixin {
  final _random = Random();

  List<TracingSessionItem>? _queue;
  TracingContent? _tracingContent;
  int _index = 0;
  bool _loading = true;
  bool _success = false;
  /// Nothing was eligible to trace from the very start (e.g. no first name
  /// and no recognized letters) — not the same as finishing the session
  /// normally, which never sets this (see [_goToNextQueueItem]).
  bool _emptyQueueAtLoad = false;
  bool _replaying = false;

  /// Whether the current item shows the dotted guide. Decided once per
  /// item in [_prepareAndPromptCurrentItem], from whether it was already
  /// traced successfully with the guide on an earlier day.
  bool _guided = true;

  /// True while an instruction is actually being spoken — the mascot
  /// ignores being tapped during that window instead of queuing a second
  /// phrase behind the first (CLAUDE.md section 10).
  bool _isSpeaking = false;

  bool _itemHadFailedAttempt = false;
  DateTime? _itemStartFirstAcquiredAt;
  int _tracedFirstTryCount = 0;
  final List<String> _newlyAcquiredGlyphs = [];

  /// A letter is drawn stroke by stroke, lifting the finger between
  /// strokes (CLAUDE.md section 10): each matched stroke's points are
  /// kept here permanently (even if a later stroke then fails) and the
  /// stroke currently being drawn is tracked separately.
  final List<List<Offset>> _completedStrokes = [];
  final Set<int> _completedStrokeIndices = {};
  List<Offset> _currentStrokePoints = [];

  /// Which stroke a replay is demonstrating (only that one, not the
  /// whole letter) — set right before [_replayController] starts.
  int? _replayStrokeIndex;

  Timer? _advanceTimer;
  late final ConfettiController _confetti;
  late final AnimationController _replayController;

  /// Pulses the next expected stroke's start dot in guided mode, so the
  /// child knows where to begin without needing to search for it.
  late final AnimationController _blinkController;

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
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _confetti.dispose();
    _replayController.dispose();
    _blinkController.dispose();
    unawaited(_audio?.stop());
    super.dispose();
  }

  void _onReplayStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _replaying = false);
    }
  }

  Future<void> _load() async {
    final tracingContent = await ref.read(tracingContentProvider.future);
    final repository = ref.read(progressRepositoryProvider);

    List<TracingSessionItem> session;
    if (widget.explicitItems != null) {
      // A specific level was tapped (CLAUDE.md section 10): no cursor, no
      // 5-item cap — just that level's items, every time.
      session = selectTracingSessionQueue(
        widget.explicitItems!,
        maxItems: widget.explicitItems!.length,
      );
    } else {
      final world = ref.read(worldProvider);
      final alphabet = await ref.read(alphabetContentProvider(world).future);
      final numbers = await ref.read(numbersContentProvider(world).future);
      final states = await repository.statesFor(
        alphabet.items.map((item) => item.id).toList(),
      );
      final firstName = ref.read(childFirstNameProvider);

      final fullQueue = buildFullTracingQueue(
        alphabetItems: alphabet.items,
        states: states,
        firstName: firstName,
        numbersContent: numbers,
        hasTracingData: (glyphKey) => tracingContent[glyphKey] != null,
      );
      final cursor = await repository.tracingQueueCursor();
      session = selectTracingSessionQueue(fullQueue, afterCursor: cursor);
    }

    if (!mounted) return;
    setState(() {
      _tracingContent = tracingContent;
      _queue = session;
      _loading = false;
      _emptyQueueAtLoad = session.isEmpty;
    });
    if (session.isNotEmpty) {
      unawaited(_prepareAndPromptCurrentItem());
    }
  }

  Future<AudioService> _audioFor(String world) async {
    final audio = await ref.read(audioServiceProvider(world).future);
    _audio = audio;
    return audio;
  }

  /// Captures the item's progress snapshot before this attempt (to detect
  /// a newly-`acquis` item later), decides whether it shows the guide, and
  /// speaks the prompt for it.
  Future<void> _prepareAndPromptCurrentItem() async {
    final item = _queue![_index].item;
    var guided = true;
    try {
      final repository = ref.read(progressRepositoryProvider);
      final snapshot = await repository.snapshotFor(item.id);
      _itemStartFirstAcquiredAt = snapshot.firstAcquiredAt;
      final today = ref.read(engineClockProvider)();
      final hasEarlierGuidedSuccess = await repository.hasTracingGuidedSuccessBefore(
        item.id,
        today,
      );
      guided = !hasEarlierGuidedSuccess;
    } catch (_) {
      _itemStartFirstAcquiredAt = null;
    }
    if (mounted) setState(() => _guided = guided);
    await _playPromptForCurrent();
  }

  /// Speaks the current item's instruction as a single, uninterrupted
  /// unit (CLAUDE.md section 10): always stops whatever was still
  /// playing first, so there is never more than one instruction in
  /// flight, and ignored (via the mascot's onTap, see build()) while one
  /// is already being spoken.
  Future<void> _playPromptForCurrent() async {
    if (!mounted) return;
    setState(() => _isSpeaking = true);
    try {
      final world = ref.read(worldProvider);
      final audio = await _audioFor(world);
      await audio.stop();
      await audio.playPrompt('trace_the_letter');
      await audio.playItem(_queue![_index].item.id);
    } catch (_) {
      // A missing or slow clip must never block the activity: the child
      // can still see the guide and trace it without the spoken prompt.
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _addPoint(Offset localPosition, Size box, {required bool newStroke}) {
    if (_success || _replaying || box.width == 0 || box.height == 0) return;
    final normalized = Offset(
      (localPosition.dx / box.width).clamp(0.0, 1.0),
      (localPosition.dy / box.height).clamp(0.0, 1.0),
    );
    setState(() {
      if (newStroke) {
        _currentStrokePoints = [normalized];
        return;
      }
      if (_currentStrokePoints.isEmpty ||
          (_currentStrokePoints.last - normalized).distance > _minDistanceBetweenPoints) {
        _currentStrokePoints.add(normalized);
      }
    });
  }

  /// Which strokes of [glyph] are still left to do, in stroke order — the
  /// first entry is the "expected next" one.
  List<int> _remainingStrokeIndices(TracingGlyph glyph) {
    return [
      for (var i = 0; i < glyph.strokes.length; i++)
        if (!_completedStrokeIndices.contains(i)) i,
    ];
  }

  /// One continuous gesture just ended: it is matched against the
  /// strokes not yet done, trying the expected one first but accepting
  /// any other that fits (CLAUDE.md section 10: a 4-year-old isn't
  /// blocked on stroke order, though it is noted — see
  /// [_recordItemCompleted]'s use of [_itemHadFailedAttempt]).
  void _onPanEnd() {
    if (_success || _replaying) return;
    final glyph = _tracingContent![_queue![_index].item.glyphKey];
    if (glyph == null) return;
    if (_currentStrokePoints.length < 2) {
      setState(() => _currentStrokePoints = []);
      return;
    }

    final tolerance = ref.read(tracingToleranceProvider);
    final remaining = _remainingStrokeIndices(glyph);
    final nextExpected = remaining.first;
    int? matchedIndex;
    for (final i in remaining) {
      if (isGoodStrokeTrace(
        referenceStroke: glyph.strokes[i],
        drawnPoints: _currentStrokePoints,
        tolerance: tolerance,
      )) {
        matchedIndex = i;
        break;
      }
    }

    if (matchedIndex == null) {
      _startReplay(nextExpected);
      return;
    }
    if (matchedIndex != nextExpected) {
      // A different stroke than expected was drawn correctly: accepted
      // (no punishment for order at this age), but counted the same way
      // as a failed attempt so it shows up in the progression.
      _itemHadFailedAttempt = true;
    }

    setState(() {
      _completedStrokeIndices.add(matchedIndex!);
      _completedStrokes.add(List.of(_currentStrokePoints));
      _currentStrokePoints = [];
    });

    if (_completedStrokeIndices.length == glyph.strokes.length) {
      setState(() => _success = true);
      unawaited(_playSuccessAudio());
      _advanceTimer?.cancel();
      _advanceTimer = Timer(_successAdvanceDelay, _onItemSucceeded);
    }
  }

  /// A failed attempt is never a punishment (CLAUDE.md rule 5): only the
  /// stroke that was being attempted is replayed and cleared — strokes
  /// already completed earlier in this same letter stay on screen.
  void _startReplay(int strokeIndex) {
    _itemHadFailedAttempt = true;
    _replayStrokeIndex = strokeIndex;
    setState(() {
      _replaying = true;
      _currentStrokePoints = [];
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

  void _onItemSucceeded() {
    if (!mounted) return;
    unawaited(_recordItemCompleted());
  }

  /// The item's single pass just succeeded: recorded in the same per-item
  /// progression the recognition games use (CLAUDE.md section 10: "comme
  /// le jeu de l'alphabet"), and — if it was guided — stamped as a guided
  /// success for today, so it is offered without the guide from the next
  /// session onward (never the same session).
  Future<void> _recordItemCompleted() async {
    final sessionItem = _queue![_index];
    final item = sessionItem.item;
    final firstTry = !_itemHadFailedAttempt;
    try {
      final repository = ref.read(progressRepositoryProvider);
      final today = ref.read(engineClockProvider)();
      if (_guided) {
        await repository.recordTracingGuidedSuccess(item.id, today);
      }
      final updated = await repository.recordAnswer(
        itemId: item.id,
        correct: true,
        firstTry: firstTry,
        today: today,
      );
      if (firstTry) _tracedFirstTryCount++;
      if (_itemStartFirstAcquiredAt == null && updated.firstAcquiredAt != null) {
        _newlyAcquiredGlyphs.add(item.glyphKey);
      }
      // A level-scoped session (CLAUDE.md section 10) never touches the
      // automatic queue's cursor: it's a deliberate practice of one pack,
      // not a turn in the rotating curriculum.
      if (widget.explicitItems == null) {
        await repository.setTracingQueueCursor(sessionItem.occurrenceKey);
      }
    } catch (_) {
      // Recording failing must never block the activity from moving on.
    }
    _goToNextQueueItem();
  }

  void _goToNextQueueItem() {
    if (!mounted) return;
    if (_index + 1 >= _queue!.length) {
      // No setState here: the last item's success stays visible (CLAUDE.md
      // section 13 pattern — never flash an unrelated fallback screen) while
      // _finishActivity resolves and either navigates away or hands the
      // result to onFinished.
      unawaited(_finishActivity());
      return;
    }
    setState(() {
      _index++;
      _success = false;
      _itemHadFailedAttempt = false;
      _completedStrokes.clear();
      _completedStrokeIndices.clear();
      _currentStrokePoints = [];
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
    final stars = starsForTracingFirstTry(_tracedFirstTryCount, _queue!.length);
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

    if (widget.levelId != null) {
      try {
        await repository
            .recordLevelStars(widget.levelId!, stars)
            .timeout(_finishActivityStepTimeout);
      } catch (_) {
        // The level path just won't show an updated best yet; never blocks
        // the celebration itself. A bare try/catch alone would not have
        // been enough here: a hung write (not a thrown error) never
        // reaches a catch without the timeout forcing it to give up.
      }
    }

    if (!mounted) return;
    final result = BravoResult(
      stars: stars,
      gameSticker: sticker,
      newlyAcquiredLetterGlyphs: _newlyAcquiredGlyphs,
    );
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished(result);
    } else {
      context.go('/bravo', extra: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_emptyQueueAtLoad) {
      return _buildEmptyQueue(context);
    }

    final item = _queue![_index].item;
    final glyph = _tracingContent![item.glyphKey];
    int? nextStrokeIndex;
    if (glyph != null && _guided && !_replaying && !_success) {
      final remaining = _remainingStrokeIndices(glyph);
      if (remaining.isNotEmpty) nextStrokeIndex = remaining.first;
    }

    final mood = _success
        ? MascotMood.happy
        : (_itemHadFailedAttempt ? MascotMood.thinking : MascotMood.idle);

    return Scaffold(
      body: GameBackdrop(
        accent: MboaKidsTheme.purple,
        child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Mascot(mood: mood, onTap: _isSpeaking ? null : _playPromptForCurrent),
            const SizedBox(height: 8),
            ProgressDots(total: _queue!.length, filled: _index),
            const SizedBox(height: 8),
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
                                    animation: Listenable.merge([
                                      _replayController,
                                      _blinkController,
                                    ]),
                                    builder: (context, _) => CustomPaint(
                                      size: box,
                                      painter: TracingCanvasPainter(
                                        glyph: glyph,
                                        completedStrokes: _completedStrokes,
                                        currentStrokePoints: _currentStrokePoints,
                                        success: _success,
                                        showGuide: _guided,
                                        nextStrokeIndex: nextStrokeIndex,
                                        blinkValue: _blinkController.value,
                                        replayStrokeIndex: _replayStrokeIndex,
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
