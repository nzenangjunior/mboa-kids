import '../content/models/alphabet_item.dart';
import '../progress/item_state.dart';

/// Which letters the tracing activity proposes, and in what order
/// (CLAUDE.md section 7: "le tracé ne propose que des lettres déjà
/// reconnues, sauf le prénom, tracé dès le début").
///
/// "Already recognized" means the child has been asked this letter at
/// least once in the touch-the-letter game — [ItemState.aApprendre] is the
/// default state for a letter never attempted, so anything else counts.
/// The first name is exempt from that check entirely and always comes
/// first, spelled out letter by letter (repeats included, so the child
/// traces the whole name), followed by the other recognized letters once
/// each, in alphabet order.
List<AlphabetItem> buildTracingQueue({
  required List<AlphabetItem> alphabetItems,
  required Map<String, ItemState> states,
  required String firstName,
  required bool Function(String glyph) hasTracingData,
}) {
  final byGlyph = {for (final item in alphabetItems) item.glyph: item};

  final queue = <AlphabetItem>[];
  final nameGlyphs = <String>{};
  for (final char in firstName.toUpperCase().split('')) {
    final item = byGlyph[char];
    if (item == null || !hasTracingData(char)) continue;
    queue.add(item);
    nameGlyphs.add(char);
  }

  for (final item in alphabetItems) {
    if (nameGlyphs.contains(item.glyph)) continue;
    if (!hasTracingData(item.glyph)) continue;
    final state = states[item.id];
    if (state == null || state == ItemState.aApprendre) continue;
    queue.add(item);
  }

  return queue;
}
