import '../../core/rewards/sticker_catalog.dart';

/// What the Bravo screen needs to celebrate one finished game
/// (CLAUDE.md section 8).
class BravoResult {
  const BravoResult({
    required this.stars,
    required this.gameSticker,
    this.newlyAcquiredLetterGlyphs = const [],
  });

  /// 1 to 3, from how many of the 5 main questions were answered
  /// correctly on the first try.
  final int stars;

  /// Always earned, whatever the score: CLAUDE.md section 8, "chaque
  /// partie terminée donne un petit autocollant".
  final GameSticker gameSticker;

  /// Letters that reached `acquis` for the first time during this game:
  /// each earns a rarer, golden sticker (CLAUDE.md section 8).
  final List<String> newlyAcquiredLetterGlyphs;
}
