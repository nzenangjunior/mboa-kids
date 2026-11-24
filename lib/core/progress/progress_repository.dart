import '../rewards/intensity_level.dart';
import 'item_progress_snapshot.dart';
import 'item_state.dart';

/// Storage + progression-engine wiring. In practice this is the app's
/// single persistence gateway: besides per-item progress it also keeps
/// the celebration intensity and the earned "fin de partie" stickers
/// (CLAUDE.md section 8), since they live in the same drift database
/// and a separate repository/connection stack for a couple of values
/// would just duplicate this one's plumbing.
///
/// [DriftProgressRepository] (real SQLite via drift) is the only
/// implementation: a native file on Android/desktop, sqlite3 compiled to
/// WebAssembly on the web dev preview (CLAUDE.md targets Android only;
/// the web path exists purely so progress survives while there is no
/// tablet at hand).
abstract class ProgressRepository {
  Future<ItemProgressSnapshot> snapshotFor(String itemId);

  /// Seeds an item directly into a given state, used for the English
  /// start set (A-E and 1-10 begin in `aRevoir`, CLAUDE.md section 7).
  Future<void> seed(String itemId, ItemState state);

  Future<ItemProgressSnapshot> recordAnswer({
    required String itemId,
    required bool correct,
    required bool firstTry,
    required DateTime today,
  });

  Future<Map<String, ItemState>> statesFor(List<String> itemIds);

  /// Records that [stickerId] (from `assets/content/stickers.json`) was
  /// earned by finishing a game. Kept forever, even duplicates: the
  /// album only needs to know it was earned at least once.
  Future<void> recordStickerEarned(String stickerId, DateTime earnedAt);

  /// Every distinct "fin de partie" sticker id ever earned.
  Future<Set<String>> earnedStickerIds();

  Future<IntensityLevel> intensity();
  Future<void> setIntensity(IntensityLevel level);

  /// Whether [itemId] was successfully traced with the guide on some day
  /// strictly before [day] — the condition for offering it without the
  /// guide (CLAUDE.md section 10: never in the same session it was first
  /// traced with the guide).
  Future<bool> hasTracingGuidedSuccessBefore(String itemId, DateTime day);

  /// Records that [itemId] was successfully traced with the guide on
  /// [day] (CLAUDE.md section 10).
  Future<void> recordTracingGuidedSuccess(String itemId, DateTime day);

  /// The opaque cursor (see `tracing_queue.dart`'s occurrence keys) for the
  /// last tracing queue item completed, across all sessions — lets the
  /// tracing activity resume where it left off instead of restarting from
  /// the first name every time (CLAUDE.md section 10: at most 5 traces
  /// per session).
  Future<String?> tracingQueueCursor();

  Future<void> setTracingQueueCursor(String cursor);

  /// The world last chosen on the home screen ('fr'/'en'), or null if
  /// never chosen yet (CLAUDE.md section 10: "le monde choisi est
  /// mémorisé").
  Future<String?> lastWorld();

  Future<void> setLastWorld(String world);

  /// The best star count ever reached on [levelId] (see `level_path.dart`
  /// for how level ids are built), or 0 if never played.
  Future<int> bestStarsFor(String levelId);

  /// Records [stars] for [levelId] if higher than the current best
  /// (CLAUDE.md section 10: a level keeps its best stars, never loses them).
  Future<void> recordLevelStars(String levelId, int stars);

  /// How many stickers + golden letters were earned the last time the
  /// album was opened (CLAUDE.md section 10, Refonte visuelle: drives the
  /// home screen's "new sticker" badge).
  Future<int> albumLastSeenCount();

  Future<void> setAlbumLastSeenCount(int count);

  /// Where each sticker/golden letter was placed in the album's scene, by
  /// its id, as normalized (dx, dy) coordinates in 0..1. Empty for any id
  /// never explicitly placed — the album then falls back to its own
  /// computed layout. Nothing writes here yet (no drag-and-drop built),
  /// but the read/write pair already exists for when it is.
  Future<Map<String, (double, double)>> stickerPositions();

  Future<void> setStickerPosition(String stickerId, double dx, double dy);

  /// Whether the home screen's first-visit hint has already played once
  /// (CLAUDE.md section 10, Refonte visuelle).
  Future<bool> hasShownPlayHint();

  Future<void> setHasShownPlayHint(bool value);

  Future<void> dispose();
}
