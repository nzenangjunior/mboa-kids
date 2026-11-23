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
import '../core/content/models/number_item.dart';
import '../core/progress/progress_repository.dart';
import '../core/progress/progress_repository_io.dart'
    if (dart.library.js_interop) '../core/progress/progress_repository_web.dart';
import '../core/progress/progression_engine.dart';
import '../core/rewards/intensity_level.dart';
import '../core/rewards/sticker_catalog.dart';
import '../core/tracing/tracing_glyph.dart';
import '../core/tracing/tracing_loader.dart';
import '../core/tracing/tracing_matcher.dart';

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

final numbersContentProvider = FutureProvider.family<NumbersContent, String>(
  (ref, world) => ref.read(contentLoaderProvider).loadNumbers(world),
);

final tracingLoaderProvider = Provider<TracingLoader>(
  (ref) => TracingLoader(rootBundle),
);

/// Key points per glyph (CLAUDE.md section 4), letters and numbers merged,
/// shared by both worlds since a glyph's shape doesn't depend on fr/en.
final tracingContentProvider = FutureProvider<TracingContent>(
  (ref) => ref.read(tracingLoaderProvider).loadAll(),
);

/// How closely a traced letter/number must match its guide to count as
/// good (CLAUDE.md section 10: "tolérance réglable"). Centralized here
/// instead of a magic number at each call site, so it is one place to
/// tune — e.g. a future parent setting for a stricter or looser mode.
final tracingToleranceProvider = Provider<TracingTolerance>(
  (ref) => defaultTracingTolerance,
);

/// The child's first name, always traceable regardless of progression
/// (CLAUDE.md section 7). There is no settings screen yet to set this from
/// (that's étape 9's parent space); hardcoded for now the same way the
/// debug panel stands in for settings elsewhere in this app.
final childFirstNameProvider = Provider<String>((ref) => 'Estrella');

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
  'fr': {
    'find_the_letter': 'Touche la lettre',
    'trace_the_letter': 'Trace la lettre',
  },
  'en': {
    'find_the_letter': 'Touch the letter',
    'trace_the_letter': 'Trace the letter',
  },
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
  final numbers = await ref.watch(numbersContentProvider(world).future);
  final locale = world == 'en' ? 'en-GB' : 'fr-FR';

  final itemAudioPaths = <String, String>{};
  final itemSpokenText = <String, String>{};
  for (final item in alphabet.items) {
    itemAudioPaths[item.id] = item.audio;
    itemSpokenText[item.id] = item.glyph;
  }
  for (var value = 0; value <= numbers.maxRecognizedValue; value++) {
    final item = numbers.itemFor(value);
    itemAudioPaths[item.id] = item.audio;
    itemSpokenText[item.id] = item.value.toString();
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
