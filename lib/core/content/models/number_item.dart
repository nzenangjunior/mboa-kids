/// A single number for one world (fr/en), derived on demand rather than
/// listed in JSON: the configurable tiers in [NumbersContent] are the
/// content (per CLAUDE.md section 5), the per-value id/audio path follow
/// a fixed convention.
class NumberItem {
  const NumberItem({required this.id, required this.value, required this.audio});

  final String id;
  final int value;
  final String audio;
}

/// A recognition tier, e.g. [0, 20].
class NumberTier {
  const NumberTier(this.min, this.max);

  final int min;
  final int max;

  bool contains(int value) => value >= min && value <= max;
}

/// The numbers content for one world, loaded from
/// `assets/content/<world>/numbers.json`.
class NumbersContent {
  const NumbersContent({
    required this.world,
    required this.recognize,
    required this.countObjectsMax,
    required this.writeMax,
    required this.countByTensMax,
  });

  final String world;
  final List<NumberTier> recognize;
  final int countObjectsMax;
  final int writeMax;
  final int countByTensMax;

  factory NumbersContent.fromJson(Map<String, dynamic> json) {
    final rawTiers = json['recognize'] as List<dynamic>;
    return NumbersContent(
      world: json['world'] as String,
      recognize: rawTiers
          .map((tier) {
            final pair = tier as List<dynamic>;
            return NumberTier(pair[0] as int, pair[1] as int);
          })
          .toList(growable: false),
      countObjectsMax: json['countObjectsMax'] as int,
      writeMax: json['writeMax'] as int,
      countByTensMax: json['countByTensMax'] as int,
    );
  }

  /// The highest value covered by any recognition tier.
  int get maxRecognizedValue =>
      recognize.map((tier) => tier.max).reduce((a, b) => a > b ? a : b);

  /// Builds the [NumberItem] for a single value, following the stable id
  /// and audio path convention (`<world>.number.<value>`).
  NumberItem itemFor(int value) {
    return NumberItem(
      id: '$world.number.$value',
      value: value,
      audio: 'audio/$world/numbers/$value.ogg',
    );
  }

  /// All items within the given tier (inclusive), in ascending order.
  List<NumberItem> itemsInTier(NumberTier tier) {
    return [for (var v = tier.min; v <= tier.max; v++) itemFor(v)];
  }
}
