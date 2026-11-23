import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/content/alphabet_round.dart';
import '../../core/content/models/alphabet_item.dart';
import '../../shared/widgets/choice_card.dart';
import '../../shared/widgets/mascot_tap_target.dart';

enum _AnswerState { waiting, correct, incorrect }

/// "Écoute et touche la lettre": the first real game (CLAUDE.md section
/// 10, step 3). The mascot speaks the target letter, the child taps one
/// of 3 choices; a wrong answer is never punished, it just shows the
/// right answer (section 2.5). Each question is a single attempt, so it
/// is always the child's "first try" at that item for progression
/// purposes (CLAUDE.md section 7).
class AlphabetGameScreen extends ConsumerStatefulWidget {
  const AlphabetGameScreen({super.key});

  @override
  ConsumerState<AlphabetGameScreen> createState() =>
      _AlphabetGameScreenState();
}

class _AlphabetGameScreenState extends ConsumerState<AlphabetGameScreen> {
  static const _questionCount = 5;

  final _random = Random();

  List<AlphabetRound>? _rounds;
  int _roundIndex = 0;
  _AnswerState _answerState = _AnswerState.waiting;
  String? _selectedId;
  bool _promptPlayedForRound = false;
  bool _roundReady = false;
  bool _aidedMode = false;

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
    _rounds ??= ref
        .read(alphabetRoundBuilderProvider)
        .buildGame(alphabet.items, questionCount: _questionCount);

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
            const SizedBox(height: 40),
            if (_answerState != _AnswerState.waiting)
              ElevatedButton(
                onPressed: _goToNextRound,
                child: const Text('Continuer', style: TextStyle(fontSize: 20)),
              ),
          ],
        ),
      ),
    );
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
      _roundReady = true;
    });
  }

  ChoiceCardState _stateFor(AlphabetItem choice, AlphabetRound round) {
    if (_answerState == _AnswerState.waiting) return ChoiceCardState.normal;
    if (choice.id == round.target.id) return ChoiceCardState.correct;
    if (choice.id == _selectedId) return ChoiceCardState.incorrect;
    return ChoiceCardState.normal;
  }

  Future<void> _playPromptForRound(String world, AlphabetRound round) async {
    final audio = await ref.read(audioServiceProvider(world).future);
    await audio.playPrompt('find_the_letter');
    await audio.playItem(round.target.id);
  }

  Future<void> _replayTarget(String world, AlphabetRound round) async {
    final audio = await ref.read(audioServiceProvider(world).future);
    await audio.playItem(round.target.id);
  }

  Future<void> _onChoiceTap(
    String world,
    AlphabetRound round,
    AlphabetItem choice,
  ) async {
    final isCorrect = choice.id == round.target.id;
    setState(() {
      _selectedId = choice.id;
      _answerState = isCorrect ? _AnswerState.correct : _AnswerState.incorrect;
    });

    await ref.read(progressRepositoryProvider).recordAnswer(
          itemId: round.target.id,
          correct: isCorrect,
          firstTry: true,
          today: DateTime.now(),
        );

    final audio = await ref.read(audioServiceProvider(world).future);
    if (isCorrect) {
      await audio.playSfx('success_chime');
    } else {
      await audio.playSfx('soft_error');
      await audio.playItem(round.target.id);
    }
  }

  void _goToNextRound() {
    if (_roundIndex + 1 >= _questionCount) {
      context.go('/bravo');
      return;
    }
    setState(() {
      _roundIndex++;
      _answerState = _AnswerState.waiting;
      _selectedId = null;
      _promptPlayedForRound = false;
      _roundReady = false;
      _aidedMode = false;
    });
  }
}
