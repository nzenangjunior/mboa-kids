/// One key point of a tracing guide, normalized to a 0..1 square
/// independent of the actual canvas size (CLAUDE.md section 4: tracing
/// key points live in JSON, one set per glyph, shared by both worlds
/// since a letter's shape doesn't depend on fr/en).
class TracingPoint {
  const TracingPoint(this.x, this.y);

  final double x;
  final double y;

  factory TracingPoint.fromJson(List<dynamic> json) {
    return TracingPoint((json[0] as num).toDouble(), (json[1] as num).toDouble());
  }
}

/// One continuous stroke of a glyph, as an ordered list of key points.
/// Order matters: it is both the drawing direction (for the arrow hint)
/// and the expected starting point (for the start-dot hint).
class TracingStroke {
  const TracingStroke(this.points);

  final List<TracingPoint> points;

  factory TracingStroke.fromJson(List<dynamic> json) {
    return TracingStroke(
      json
          .map((point) => TracingPoint.fromJson(point as List<dynamic>))
          .toList(growable: false),
    );
  }
}

/// The tracing guide for one glyph (e.g. "A"): one or more strokes drawn
/// in order.
class TracingGlyph {
  const TracingGlyph({required this.glyph, required this.strokes});

  final String glyph;
  final List<TracingStroke> strokes;

  factory TracingGlyph.fromJson(String glyph, Map<String, dynamic> json) {
    final rawStrokes = json['strokes'] as List<dynamic>;
    return TracingGlyph(
      glyph: glyph,
      strokes: rawStrokes
          .map((stroke) => TracingStroke.fromJson(stroke as List<dynamic>))
          .toList(growable: false),
    );
  }
}

/// All tracing guides loaded from `assets/content/tracing/letters.json`.
class TracingContent {
  const TracingContent(this.glyphs);

  final Map<String, TracingGlyph> glyphs;

  factory TracingContent.fromJson(Map<String, dynamic> json) {
    final rawGlyphs = json['glyphs'] as Map<String, dynamic>;
    return TracingContent(
      rawGlyphs.map(
        (glyph, value) => MapEntry(
          glyph,
          TracingGlyph.fromJson(glyph, value as Map<String, dynamic>),
        ),
      ),
    );
  }

  /// The guide for [glyph], or null if this glyph has no tracing data yet
  /// (CLAUDE.md section 9: adding content must never require a code change,
  /// so a caller should skip a missing glyph rather than crash).
  TracingGlyph? operator [](String glyph) => glyphs[glyph];
}
