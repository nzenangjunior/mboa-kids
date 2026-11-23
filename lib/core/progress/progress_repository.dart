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

  Future<void> dispose();
}
