import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../core/audio/audio_service.dart';
import '../core/audio/clip_audio_service.dart';
import '../core/audio/clip_player.dart';
import '../core/audio/speech_engine.dart';
import '../core/audio/tts_fallback_audio_service.dart';
import '../core/content/alphabet_round.dart';
import '../core/content/content_loader.dart';
import '../core/content/models/alphabet_item.dart';
import '../core/progress/progress_database.dart';
import '../core/progress/progress_repository.dart';
import '../core/progress/progression_engine.dart';

/// The world (fr/en) chosen for the current session. Never changed mid
/// game: CLAUDE.md section 2.6 says the two worlds are never mixed within
/// one session.
final worldProvider = StateProvider<String>((ref) => 'fr');

final contentLoaderProvider = Provider<ContentLoader>(
  (ref) => ContentLoader(rootBundle),
);

final alphabetRoundBuilderProvider = Provider<AlphabetRoundBuilder>(
  (ref) => AlphabetRoundBuilder(),
);

const progressionEngine = ProgressionEngine();

/// One progression database for the whole app: item ids already encode
/// their world (e.g. `en.letter.F`), so there is nothing to separate by
/// world here.
final progressDatabaseProvider = Provider<ProgressDatabase>((ref) {
  final db = ProgressDatabase();
  ref.onDispose(db.close);
  return db;
});

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(
    ref.watch(progressDatabaseProvider),
    engine: progressionEngine,
  ),
);

final alphabetContentProvider = FutureProvider.family<AlphabetContent, String>(
  (ref, world) => ref.read(contentLoaderProvider).loadAlphabet(world),
);

const _promptSpokenText = {
  'fr': {'find_the_letter': 'Touche la lettre'},
  'en': {'find_the_letter': 'Touch the letter'},
};

const _praiseSpokenText = {
  'fr': ['Bravo !', 'Super !', 'Génial !'],
  'en': ['Well done!', 'Great job!', 'Super!'],
};

/// The audio service for the given world, wired with the alphabet clips
/// already known for that world and a TTS fallback for anything missing
/// (CLAUDE.md section 6).
final audioServiceProvider = FutureProvider.family<AudioService, String>((
  ref,
  world,
) async {
  final alphabet = await ref.watch(alphabetContentProvider(world).future);
  final locale = world == 'en' ? 'en-GB' : 'fr-FR';

  final itemAudioPaths = <String, String>{};
  final itemSpokenText = <String, String>{};
  for (final item in alphabet.items) {
    itemAudioPaths[item.id] = item.audio;
    itemSpokenText[item.id] = item.glyph;
  }

  final fallback = TtsFallbackAudioService(
    speechEngine: FlutterTtsSpeechEngine(),
    locale: locale,
    itemSpokenText: itemSpokenText,
    promptSpokenText: _promptSpokenText[world] ?? const {},
    praiseSpokenText: _praiseSpokenText[world] ?? const ['Bravo !'],
  );

  return ClipAudioService(
    player: JustAudioClipPlayer(),
    fallback: fallback,
    itemAudioPaths: itemAudioPaths,
    promptAudioPaths: const {},
    sfxAudioPaths: const {},
  );
});
