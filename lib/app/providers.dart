import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../core/audio/audio_service.dart';
import '../core/audio/clip_audio_service.dart';
import '../core/audio/clip_player.dart';
import '../core/audio/speech_engine.dart';
import '../core/audio/tts_fallback_audio_service.dart';
import '../core/content/content_loader.dart';
import '../core/content/models/alphabet_item.dart';
import '../core/progress/progress_repository.dart';
import '../core/progress/progress_repository_io.dart'
    if (dart.library.js_interop) '../core/progress/progress_repository_web.dart';
import '../core/progress/progression_engine.dart';
import '../core/rewards/intensity_level.dart';
import '../core/rewards/sticker_catalog.dart';

/// The world (fr/en) chosen for the current session. Never changed mid
/// game: CLAUDE.md section 2.6 says the two worlds are never mixed within
/// one session.
final worldProvider = StateProvider<String>((ref) => 'fr');

final contentLoaderProvider = Provider<ContentLoader>(
  (ref) => ContentLoader(rootBundle),
);

const progressionEngine = ProgressionEngine();

/// One progression repository for the whole app: item ids already encode
/// their world (e.g. `en.letter.F`), so there is nothing to separate by
/// world here. Always real SQLite via drift: a native file on
/// Android/desktop, sqlite3 compiled to WebAssembly on the web dev preview
/// (CLAUDE.md targets Android only; the web path exists purely so progress
/// survives while there is no tablet at hand).
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final repository = createDefaultProgressRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

/// How many days to add to [DateTime.now] when recording an answer. The
/// progression engine itself never calls [DateTime.now] — every caller
/// passes "today" in explicitly — so the debug panel's "Simuler +1 jour"
/// button can fast-forward the whole app by bumping this.
final simulatedDayOffsetProvider = StateProvider<int>((ref) => 0);

final engineClockProvider = Provider<DateTime Function()>((ref) {
  final offsetDays = ref.watch(simulatedDayOffsetProvider);
  return () => DateTime.now().add(Duration(days: offsetDays));
});

final alphabetContentProvider = FutureProvider.family<AlphabetContent, String>(
  (ref, world) => ref.read(contentLoaderProvider).loadAlphabet(world),
);

final stickerCatalogProvider = Provider<StickerCatalog>(
  (ref) => StickerCatalog(rootBundle),
);

final stickerCatalogListProvider = FutureProvider<List<GameSticker>>(
  (ref) => ref.read(stickerCatalogProvider).load(),
);

/// Celebration intensity (CLAUDE.md section 8), persisted, `normal` by
/// default. There is no settings screen yet to change it from (that's
/// étape 9), so the debug panel exposes a temporary way to test it.
final intensityProvider = FutureProvider<IntensityLevel>(
  (ref) => ref.read(progressRepositoryProvider).intensity(),
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
