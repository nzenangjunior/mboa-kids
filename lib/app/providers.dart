import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;
import 'package:flutter_tts/flutter_tts.dart';

import '../core/audio/audio_service.dart';
import '../core/audio/clip_audio_service.dart';
import '../core/audio/clip_player.dart';
import '../core/audio/speech_engine.dart';
import '../core/audio/tts_fallback_audio_service.dart';
import '../core/content/alphabet_game_composer.dart';
import '../core/content/content_loader.dart';
import '../core/content/models/alphabet_item.dart';
import '../core/content/models/number_item.dart';
import '../core/progress/item_state.dart';
import '../core/progress/level_path.dart';
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
/// (that's étape 10's parent space); hardcoded for now the same way the
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
/// étape 10), so the debug panel exposes a temporary way to test it.
final intensityProvider = FutureProvider<IntensityLevel>(
  (ref) => ref.read(progressRepositoryProvider).intensity(),
);

/// How long a daily path session runs before stopping early with the
/// "mascotte dort" screen (CLAUDE.md section 10), 10 minutes by default.
/// Config only for now — there is no parent settings screen yet to make
/// it adjustable (that's étape 10).
final sessionDurationProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 10),
);

/// Set by the daily path right before navigating to Bravo when the
/// session duration ran out (CLAUDE.md section 7: "après le jeu en cours
/// → écran « la mascotte dort »"). [BravoScreen] reads and resets it once,
/// to decide whether its own button leads to `/mascot-sleeping` instead
/// of straight to the home screen. A provider rather than a route
/// argument: it only exists to carry this one transient flag between two
/// screens in the same navigation, without changing the `BravoResult`
/// extra that every other Bravo navigation already relies on.
final dailyPathSleepsAfterProvider = StateProvider<bool>((ref) => false);

/// How long a level's best-stars lookup waits before giving up and
/// showing 0 instead (CLAUDE.md section 13: a slow or stuck read must
/// never freeze the whole path — the level still shows, just without its
/// best score yet).
const _levelStarsLookupTimeout = Duration(seconds: 3);

Future<int> _bestStarsOrZero(ProgressRepository repository, String levelId) async {
  try {
    return await repository.bestStarsFor(levelId).timeout(_levelStarsLookupTimeout);
  } catch (error) {
    debugPrint('[levels] bestStarsFor("$levelId") timed out or failed: $error');
    return 0;
  }
}

/// Same reasoning as [_bestStarsOrZero]: every level still renders — with
/// nothing marked as progressed yet — rather than the whole path hanging
/// on one slow or stuck read.
Future<Map<String, ItemState>> _statesOrEmpty(
  ProgressRepository repository,
  List<String> itemIds,
) async {
  try {
    return await repository.statesFor(itemIds).timeout(_levelStarsLookupTimeout);
  } catch (error) {
    debugPrint('[levels] statesFor(...) timed out or failed: $error');
    return const {};
  }
}

/// One level on the alphabet island's path (CLAUDE.md section 10): 1
/// level = 1 pack of letters, locked/open/done with its best stars.
final alphabetLevelsProvider = FutureProvider.family<List<PackLevel>, String>((
  ref,
  world,
) async {
  final alphabet = await ref.watch(alphabetContentProvider(world).future);
  final repository = ref.read(progressRepositoryProvider);
  final startIds = startUnlockedAlphabetItemIds(world, alphabet.items);
  final states = await _statesOrEmpty(repository, alphabet.items.map((i) => i.id).toList());

  final packCount = ((alphabet.items.length - startIds.length) / alphabet.packSize).ceil();
  final bestStarsByPack = <int, int>{};
  for (var n = 1; n <= packCount; n++) {
    bestStarsByPack[n] = await _bestStarsOrZero(repository, '$world.alphabet.pack$n');
  }

  return buildPackLevelPath(
    allItemsInOrder: alphabet.items,
    startUnlockedItemIds: startIds,
    states: states,
    packSize: alphabet.packSize,
    bestStarsFor: (packNumber) => bestStarsByPack[packNumber] ?? 0,
  );
});

/// One level on the tracing island's path: the special first-name level,
/// then the same packs as the alphabet island, filtered to glyphs that
/// already have tracing data (CLAUDE.md section 10).
typedef TracingLevelView = ({
  bool isNameLevel,
  int? packNumber,
  List<String> glyphs,
  LevelState state,
  int bestStars,
});

final tracingLevelsProvider = FutureProvider.family<List<TracingLevelView>, String>((
  ref,
  world,
) async {
  final alphabet = await ref.watch(alphabetContentProvider(world).future);
  final tracingContent = await ref.watch(tracingContentProvider.future);
  final repository = ref.read(progressRepositoryProvider);
  final firstName = ref.read(childFirstNameProvider);
  final startIds = startUnlockedAlphabetItemIds(world, alphabet.items);
  final states = await _statesOrEmpty(repository, alphabet.items.map((i) => i.id).toList());

  final itemIdByGlyph = {for (final item in alphabet.items) item.glyph: item.id};
  final nameState = tracingNameLevelState(
    firstName: firstName,
    itemIdByGlyph: itemIdByGlyph,
    states: states,
  );
  final nameBestStars = await _bestStarsOrZero(repository, '$world.tracing.name');

  final packCount = ((alphabet.items.length - startIds.length) / alphabet.packSize).ceil();
  final bestStarsByPack = <int, int>{};
  for (var n = 1; n <= packCount; n++) {
    bestStarsByPack[n] = await _bestStarsOrZero(repository, '$world.tracing.pack$n');
  }

  final packLevels = buildPackLevelPath(
    allItemsInOrder: alphabet.items,
    startUnlockedItemIds: startIds,
    states: states,
    packSize: alphabet.packSize,
    bestStarsFor: (packNumber) => bestStarsByPack[packNumber] ?? 0,
  ).where((level) => level.glyphs.every((glyph) => tracingContent[glyph] != null));

  return [
    (
      isNameLevel: true,
      packNumber: null,
      glyphs: firstName.toUpperCase().split('').toSet().toList(),
      state: nameState,
      bestStars: nameBestStars,
    ),
    for (final level in packLevels)
      (
        isNameLevel: false,
        packNumber: level.packNumber,
        glyphs: level.glyphs,
        state: level.state,
        bestStars: level.bestStars,
      ),
  ];
});

/// Stickers + golden (acquired) letters earned so far, across both worlds
/// — the same count the album screen itself shows. Used by the home
/// screen's "new sticker" badge (CLAUDE.md section 10, Refonte visuelle).
final albumTotalEarnedCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.read(progressRepositoryProvider);
  final fr = await ref.watch(alphabetContentProvider('fr').future);
  final en = await ref.watch(alphabetContentProvider('en').future);
  final earnedStickerIds = await repository.earnedStickerIds();

  var acquiredCount = 0;
  for (final item in [...fr.items, ...en.items]) {
    final snapshot = await repository.snapshotFor(item.id);
    if (snapshot.firstAcquiredAt != null) acquiredCount++;
  }
  return earnedStickerIds.length + acquiredCount;
});

final albumHasNewStickerProvider = FutureProvider<bool>((ref) async {
  final total = await ref.watch(albumTotalEarnedCountProvider.future);
  final repository = ref.read(progressRepositoryProvider);
  int lastSeen;
  try {
    lastSeen = await repository.albumLastSeenCount().timeout(_levelStarsLookupTimeout);
  } catch (error) {
    debugPrint('[album] albumLastSeenCount() timed out or failed: $error');
    lastSeen = 0;
  }
  return total > lastSeen;
});

const _promptSpokenText = {
  'fr': {
    'find_the_letter': 'Touche la lettre',
    'trace_the_letter': 'Trace la lettre',
    'home_screen': 'Touche pour jouer !',
    'tap_big_button': 'Touche le gros bouton pour jouer !',
    'island_map': 'Choisis une île',
    'choose_level': 'Choisis un niveau',
    'island_locked': 'Pas encore !',
    'mascot_sleeping': 'La mascotte dort, à bientôt !',
    'daily_path_intro': 'Des lettres, puis on écrit, puis une étoile !',
    'daily_path_to_tracing': 'Bravo ! Maintenant on écrit !',
  },
  'en': {
    'find_the_letter': 'Touch the letter',
    'trace_the_letter': 'Trace the letter',
    'home_screen': 'Touch to play!',
    'tap_big_button': 'Touch the big button to play!',
    'island_map': 'Choose an island',
    'choose_level': 'Choose a level',
    'island_locked': 'Not yet!',
    'mascot_sleeping': 'The mascot is asleep, see you soon!',
    'daily_path_intro': 'Letters, then writing, then a star!',
    'daily_path_to_tracing': 'Well done! Now let\'s write!',
  },
};

const _praiseSpokenText = {
  'fr': ['Bravo !', 'Super !', 'Génial !'],
  'en': ['Well done!', 'Great job!', 'Super!'],
};

/// Every non-verbal sound effect the app plays, by the name [AudioService
/// .playSfx] is called with — shared across worlds, since a sound effect
/// isn't spoken language (CLAUDE.md section 6, path convention
/// `audio/sfx/<name>.ogg`; see also `assets/audio/MANIFEST.csv`).
const _sfxNames = ['success_chime', 'soft_error', 'baobab'];

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

  // Path convention matching `assets/audio/MANIFEST.csv`: dropping a file
  // at one of these paths (CLAUDE.md section 6) makes it play instead of
  // the TTS fallback above, with no code change — this was previously
  // only wired for letters/numbers, leaving every prompt/praise/sfx
  // clip unreachable even once recorded.
  final promptAudioPaths = <String, String>{
    for (final key in (_promptSpokenText[world] ?? const {}).keys)
      key: 'audio/$world/prompts/$key.ogg',
  };
  final praiseCount = (_praiseSpokenText[world] ?? const ['Bravo !']).length;
  final praiseAudioPaths = [
    for (var i = 0; i < praiseCount; i++) 'audio/$world/praise/$i.ogg',
  ];
  final sfxAudioPaths = <String, String>{
    for (final name in _sfxNames) name: 'audio/sfx/$name.ogg',
  };

  return ClipAudioService(
    player: JustAudioClipPlayer(),
    fallback: fallback,
    itemAudioPaths: itemAudioPaths,
    promptAudioPaths: promptAudioPaths,
    sfxAudioPaths: sfxAudioPaths,
    praiseAudioPaths: praiseAudioPaths,
  );
});

/// Whether the device has the exact voice each world's TTS fallback asks
/// for installed (CLAUDE.md §7: en-GB, fr-FR — never a generic English or
/// French). Surfaced in `/debug/progress` so a missing voice on a test
/// phone is visible without plugging it into a computer to read logs.
final voiceAvailabilityProvider = FutureProvider<Map<String, bool>>((ref) async {
  final tts = FlutterTts();
  final result = <String, bool>{};
  for (final locale in const ['en-GB', 'fr-FR']) {
    try {
      final available = await tts.isLanguageAvailable(locale);
      result[locale] = available == true;
    } catch (error) {
      debugPrint('[voices] isLanguageAvailable("$locale") failed: $error');
      result[locale] = false;
    }
  }
  return result;
});
