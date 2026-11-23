import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/audio/audio_service.dart';
import '../../core/content/alphabet_game_composer.dart';
import '../../core/content/alphabet_round.dart';
import '../../core/content/models/alphabet_item.dart';
import '../../core/progress/item_state.dart';
import '../../core/progress/pack_unlocker.dart';
import '../../core/rewards/star_rating.dart';
import '../../core/rewards/sticker_catalog.dart';
import '../../shared/widgets/choice_card.dart';
import '../../shared/widgets/mascot_tap_target.dart';
import '../rewards/bravo_result.dart';

enum _AnswerState { waiting, correct, incorrect }

const _autoAdvanceDelay = Duration(milliseconds: 1500);
const _wrongAnswerHighlightDuration = Duration(seconds: 1);

/// "Écoute et touche la lettre": the first real game (CLAUDE.md section
/// 10, step 3). The mascot speaks the target letter, the child taps one
/// of 3 choices; a wrong answer is never punished, it just shows the
/// right answer, replays the instruction, and the same letter is asked
/// again (not counted as a first try) before coming back once more at
/// the end of the game (CLAUDE.md section 2.5 and 7). Questions are
/// chosen from the real progression state: only unlocked letters appear,
/// mixing known and new ones (CLAUDE.md section 7).
class AlphabetGameScreen extends ConsumerStatefulWidget {
  const AlphabetGameScreen({super.key});

  @override
  ConsumerState<AlphabetGameScreen> createState() =>
      _AlphabetGameScreenState();
}

class _AlphabetGameScreenState extends ConsumerState<AlphabetGameScreen> {
  final _random = Random();

  bool _gameStarting = false;
  AlphabetGameComposer? _composer;
  List<AlphabetItem>? _unlockedPool;
  List<AlphabetRound>? _rounds;
  int _mainRoundCount = 0;
  final List<String> _endOfGameQueue = [];

  int _mainCorrectFirstTryCount = 0;
  final List<String> _newlyAcquiredGlyphs = [];
  DateTime? _roundStartFirstAcquiredAt;

  int _roundIndex = 0;
  _AnswerState _answerState = _AnswerState.waiting;
  String? _selectedId;
  bool _promptPlayedForRound = false;
  bool _roundReady = false;
  bool _aidedMode = false;
  bool _isRetry = false;

  Timer? _advanceTimer;

  /// Cached the first time it resolves (see [_audioFor]), so [dispose] can
  /// stop it without touching `ref`: Riverpod forbids `ref.read` once a
  /// widget is being unmounted, which is exactly when a screen change (the
  /// scenario this is meant to guard against) calls dispose.
  AudioService? _audio;

  @override
  void dispose() {
    _advanceTimer?.cancel();
    // Nothing queued for this screen's world should keep playing (or keep
    // blocking future calls, see FlutterTtsSpeechEngine) once the child has
    // left it (CLAUDE.md section 13).
    unawaited(_audio?.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final world = ref.watch(worldProvider);
    final alphabetAsync = ref.watch(alphabetContentProvider(world));

    return alphabetAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) =>
          const Scaffold(body: Center(child: Text('Erreur de chargement'))),
      data: (alphabet) => _buildGame(context, world, alphabet),
    );
  }

  Widget _buildGame(BuildContext context, String world, AlphabetContent alphabet) {
    if (_rounds == null) {
      if (!_gameStarting) {
        _gameStarting = true;
        _startGame(world, alphabet);
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_roundReady) {
      _prepareRound(_rounds![_roundIndex]);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final round = _rounds![_roundIndex];

    if (!_promptPlayedForRound) {
      _promptPlayedForRound = true;
      _playPromptForRound(world, round);
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MascotTapTarget(onTap: () => _replayTarget(world, round)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: round.choices.map((choice) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ChoiceCard(
                    key: Key('choice-${choice.id}'),
                    label: choice.glyph,
                    state: _stateFor(choice, round),
                    isHinted: _aidedMode && choice.id == round.target.id,
                    onTap: _answerState == _AnswerState.waiting
                        ? () => _onChoiceTap(world, round, choice)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Seeds the English start set on a brand-new profile, reads the real
  /// progression state, and builds the game from it (CLAUDE.md section 7).
  Future<void> _startGame(String world, AlphabetContent alphabet) async {
    final repository = ref.read(progressRepositoryProvider);
    final startIds = startUnlockedAlphabetItemIds(world, alphabet.items);

    if (startIds.isNotEmpty) {
      final existing = await repository.statesFor(startIds.toList());
      if (existing.isEmpty) {
        for (final id in startIds) {
          await repository.seed(id, ItemState.aRevoir);
        }
      }
    }

    final allIds = alphabet.items.map((i) => i.id).toList();
    final states = await repository.statesFor(allIds);
    final composer = AlphabetGameComposer(
      random: _random,
      packUnlocker: PackUnlocker(packSize: alphabet.packSize),
    );
    final unlockedPool = composer.unlockedPool(
      allItemsInOrder: alphabet.items,
      startUnlockedItemIds: startIds,
      states: states,
    );
    final rounds = composer.buildGame(
      allItemsInOrder: alphabet.items,
      startUnlockedItemIds: startIds,
      states: states,
    );

    if (!mounted) return;
    setState(() {
      _composer = composer;
      _unlockedPool = unlockedPool;
      _rounds = rounds;
      _mainRoundCount = rounds.length;
    });
  }

  Future<void> _prepareRound(AlphabetRound round) async {
    final repository = ref.read(progressRepositoryProvider);
    final snapshot = await repository.snapshotFor(round.target.id);
    final aided = progressionEngine.shouldUseAidedMode(snapshot);

    if (!mounted) return;
    setState(() {
      if (aided) {
        _rounds![_roundIndex] = round.trimmedTo(1, _random);
      }
      _aidedMode = aided;
      _roundStartFirstAcquiredAt = snapshot.firstAcquiredAt;
      _roundReady = true;
    });
  }

  ChoiceCardState _stateFor(AlphabetItem choice, AlphabetRound round) {
    if (_answerState == _AnswerState.waiting) return ChoiceCardState.normal;
    if (choice.id == round.target.id) return ChoiceCardState.correct;
    if (choice.id == _selectedId) return ChoiceCardState.incorrect;
    return ChoiceCardState.normal;
  }

  /// Resolves the audio service and caches it in [_audio], so [dispose]
  /// has something to stop without needing `ref` at that point.
  Future<AudioService> _audioFor(String world) async {
    final audio = await ref.read(audioServiceProvider(world).future);
    _audio = audio;
    return audio;
  }

  Future<void> _playPromptForRound(String world, AlphabetRound round) async {
    final audio = await _audioFor(world);
    await audio.playPrompt('find_the_letter');
    await audio.playItem(round.target.id);
  }

  Future<void> _replayTarget(String world, AlphabetRound round) async {
    final audio = await _audioFor(world);
    await audio.playItem(round.target.id);
  }

  Future<void> _onChoiceTap(
    String world,
    AlphabetRound round,
    AlphabetItem choice,
  ) async {
    final isCorrect = choice.id == round.target.id;
    final firstTry = !_isRetry;
    final isMainRound = _roundIndex < _mainRoundCount;
    setState(() {
      _selectedId = choice.id;
      _answerState = isCorrect ? _AnswerState.correct : _AnswerState.incorrect;
    });

    final updated = await ref.read(progressRepositoryProvider).recordAnswer(
          itemId: round.target.id,
          correct: isCorrect,
          firstTry: firstTry,
          today: ref.read(engineClockProvider)(),
        );

    if (_roundStartFirstAcquiredAt == null && updated.firstAcquiredAt != null) {
      _newlyAcquiredGlyphs.add(round.target.glyph);
    }

    if (isCorrect && isMainRound && firstTry) {
      _mainCorrectFirstTryCount++;
    }
    if (!isCorrect && !_isRetry && !_endOfGameQueue.contains(round.target.id)) {
      _endOfGameQueue.add(round.target.id);
    }

    // The timer that unlocks the round (advance on correct, retry on
    // wrong) is scheduled here, before touching audio at all. Whatever
    // happens to playback below — a clip that never resolves, a TTS
    // phrase the browser never reports as finished — the child's taps
    // must never stay locked out because of it (CLAUDE.md section 13):
    // the short feedback timer is the only lock, and it always fires.
    _advanceTimer?.cancel();
    _advanceTimer = Timer(
      isCorrect ? _autoAdvanceDelay : _wrongAnswerHighlightDuration,
      isCorrect ? _goToNextRound : () => _retrySameRound(round),
    );

    unawaited(_playAnswerFeedbackAudio(world, isCorrect, round));
  }

  Future<void> _playAnswerFeedbackAudio(
    String world,
    bool isCorrect,
    AlphabetRound round,
  ) async {
    try {
      final audio = await _audioFor(world);
      if (isCorrect) {
        await _playCorrectAnswerAudio(audio);
      } else {
        // The correct answer glows for a fixed, predictable second; the
        // instruction replay (which can take longer to actually speak) runs
        // alongside it rather than gating the retry.
        await _playWrongAnswerAudio(audio, round);
      }
    } catch (_) {
      // Playback failing (or simply never finishing) must never affect the
      // round: the timer scheduled in _onChoiceTap already controls when
      // it unlocks, independently of this.
    }
  }

  Future<void> _playCorrectAnswerAudio(AudioService audio) async {
    await audio.playSfx('success_chime');
    await audio.playPraise();
  }

  Future<void> _playWrongAnswerAudio(AudioService audio, AlphabetRound round) async {
    await audio.playSfx('soft_error');
    await audio.playPrompt('find_the_letter');
    await audio.playItem(round.target.id);
  }

  void _retrySameRound(AlphabetRound round) {
    if (!mounted) return;
    setState(() {
      _isRetry = true;
      _answerState = _AnswerState.waiting;
      _selectedId = null;
      _promptPlayedForRound = false;
      _roundReady = false;
    });
  }

  void _goToNextRound() {
    if (!mounted) return;

    if (_roundIndex + 1 < _rounds!.length) {
      setState(() {
        _roundIndex++;
        _answerState = _AnswerState.waiting;
        _selectedId = null;
        _promptPlayedForRound = false;
        _roundReady = false;
        _aidedMode = false;
        _isRetry = false;
      });
      return;
    }

    if (_endOfGameQueue.isNotEmpty) {
      final missedId = _endOfGameQueue.removeAt(0);
      final missedItem = _unlockedPool!.firstWhere((i) => i.id == missedId);
      final extraRound = _composer!.buildRoundFor(missedItem, _unlockedPool!);
      setState(() {
        _rounds!.add(extraRound);
        _roundIndex++;
        _answerState = _AnswerState.waiting;
        _selectedId = null;
        _promptPlayedForRound = false;
        _roundReady = false;
        _aidedMode = false;
        _isRetry = true;
      });
      return;
    }

    _finishGame();
  }

  /// How long [_finishGame] waits on the sticker catalog and the database
  /// write before giving up on them. Found by hand: a slow or stuck asset
  /// load here used to leave the round's `_answerState` locked forever —
  /// nothing ever reset it back to `waiting`, since the retry/advance
  /// timers that normally do that only cover a single round, not the
  /// finish step after the last one (CLAUDE.md section 13). Finishing the
  /// game (with a built-in sticker instead of a catalog one, this one
  /// time) matters more than waiting indefinitely for either.
  static const _finishGameStepTimeout = Duration(seconds: 4);

  static const _fallbackSticker = GameSticker(id: 'sticker.fallback', emoji: '⭐');

  Future<void> _finishGame() async {
    final repository = ref.read(progressRepositoryProvider);
    var sticker = _fallbackSticker;
    try {
      final catalog = await ref
          .read(stickerCatalogListProvider.future)
          .timeout(_finishGameStepTimeout);
      sticker = pickRandomSticker(catalog, _random);
      await repository
          .recordStickerEarned(sticker.id, ref.read(engineClockProvider)())
          .timeout(_finishGameStepTimeout);
    } catch (_) {
      // Keep the built-in sticker and move on regardless of what failed.
    }

    if (!mounted) return;
    context.go(
      '/bravo',
      extra: BravoResult(
        stars: starsForFirstTryCorrect(_mainCorrectFirstTryCount),
        gameSticker: sticker,
        newlyAcquiredLetterGlyphs: _newlyAcquiredGlyphs,
      ),
    );
  }
}
