import '../content/models/alphabet_item.dart';
import '../content/models/number_item.dart';
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

/// Digits 1 to [NumbersContent.writeMax] with tracing data available.
/// Unlike letters, numbers are offered unconditionally regardless of
/// progression state: there is no numbers-recognition game yet (CLAUDE.md
/// section 10, step 7, still to come) to seed a starting state the way
/// [buildTracingQueue] relies on for letters, so until that exists these
/// are treated the same way the first name is — always traceable.
List<NumberItem> buildNumberTracingQueue({
  required NumbersContent numbersContent,
  required bool Function(String glyph) hasTracingData,
}) {
  return [
    for (var value = 1; value <= numbersContent.writeMax; value++)
      if (hasTracingData(value.toString())) numbersContent.itemFor(value),
  ];
}

/// One item offered by the tracing activity, letter or number alike: the
/// screen only needs a stable id (for progress and audio) and the glyph
/// key under which its guide is stored in [TracingContent].
class TracingQueueItem {
  const TracingQueueItem({required this.id, required this.glyphKey});

  final String id;
  final String glyphKey;
}

/// The full tracing queue: the child's name and recognized letters, then
/// the available numbers, as one uniform list for the screen to drive.
List<TracingQueueItem> buildFullTracingQueue({
  required List<AlphabetItem> alphabetItems,
  required Map<String, ItemState> states,
  required String firstName,
  required NumbersContent numbersContent,
  required bool Function(String glyph) hasTracingData,
}) {
  final letters = buildTracingQueue(
    alphabetItems: alphabetItems,
    states: states,
    firstName: firstName,
    hasTracingData: hasTracingData,
  );
  final numbers = buildNumberTracingQueue(
    numbersContent: numbersContent,
    hasTracingData: hasTracingData,
  );
  return [
    for (final item in letters) TracingQueueItem(id: item.id, glyphKey: item.glyph),
    for (final item in numbers)
      TracingQueueItem(id: item.id, glyphKey: item.value.toString()),
  ];
}

/// At most this many items are traced per session (CLAUDE.md section 10).
const tracingMaxItemsPerSession = 5;

/// One item selected for a session, paired with the opaque cursor to
/// persist once it is completed (see [selectTracingSessionQueue]).
class TracingSessionItem {
  const TracingSessionItem({required this.item, required this.occurrenceKey});

  final TracingQueueItem item;
  final String occurrenceKey;
}

/// A stable "id#occurrence" key for the item at [index] in [fullQueue].
/// An occurrence number is needed, not just the id, because a repeated
/// letter in the name (e.g. the two E's in ESTRELLA) would otherwise be
/// ambiguous — this disambiguates them while staying stable across
/// sessions even as later items are added to the queue.
String _occurrenceKeyAt(List<TracingQueueItem> fullQueue, int index) {
  final id = fullQueue[index].id;
  var occurrence = 0;
  for (var i = 0; i <= index; i++) {
    if (fullQueue[i].id == id) occurrence++;
  }
  return '$id#$occurrence';
}

/// Selects up to [maxItems] items from [fullQueue] to trace this session
/// (CLAUDE.md section 10: 5 max, resuming after [afterCursor] instead of
/// restarting from the first name every time — a longer name than that is
/// simply split over several sessions). Wraps back to the start once the
/// end of the queue is reached, but never repeats an item within the same
/// session.
List<TracingSessionItem> selectTracingSessionQueue(
  List<TracingQueueItem> fullQueue, {
  String? afterCursor,
  int maxItems = tracingMaxItemsPerSession,
}) {
  if (fullQueue.isEmpty) return const [];

  var startIndex = 0;
  if (afterCursor != null) {
    for (var i = 0; i < fullQueue.length; i++) {
      if (_occurrenceKeyAt(fullQueue, i) == afterCursor) {
        startIndex = (i + 1) % fullQueue.length;
        break;
      }
    }
  }

  final count = maxItems < fullQueue.length ? maxItems : fullQueue.length;
  final session = <TracingSessionItem>[];
  for (var step = 0; step < count; step++) {
    final index = (startIndex + step) % fullQueue.length;
    session.add(
      TracingSessionItem(
        item: fullQueue[index],
        occurrenceKey: _occurrenceKeyAt(fullQueue, index),
      ),
    );
  }
  return session;
}
