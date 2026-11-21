import 'word_ref.dart';

/// A single letter of the alphabet for one world (fr/en).
///
/// [id] is the stable identifier progression is stored against
/// (e.g. "en.letter.F"), per CLAUDE.md section 7.
class AlphabetItem {
  const AlphabetItem({
    required this.id,
    required this.glyph,
    required this.lower,
    required this.audio,
    required this.word,
  });

  final String id;
  final String glyph;
  final String lower;
  final String audio;
  final WordRef word;

  factory AlphabetItem.fromJson(Map<String, dynamic> json) {
    return AlphabetItem(
      id: json['id'] as String,
      glyph: json['glyph'] as String,
      lower: json['lower'] as String,
      audio: json['audio'] as String,
      word: WordRef.fromJson(json['word'] as Map<String, dynamic>),
    );
  }
}

/// The alphabet content for one world, loaded from
/// `assets/content/<world>/alphabet.json`.
class AlphabetContent {
  const AlphabetContent({
    required this.world,
    required this.packSize,
    required this.items,
  });

  final String world;
  final int packSize;
  final List<AlphabetItem> items;

  factory AlphabetContent.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>;
    return AlphabetContent(
      world: json['world'] as String,
      packSize: json['packSize'] as int,
      items: rawItems
          .map((item) => AlphabetItem.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}
