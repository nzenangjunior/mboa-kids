import 'dart:convert';

import 'package:flutter/services.dart';

import 'tracing_glyph.dart';

/// Reads `assets/content/tracing/letters.json` (CLAUDE.md section 4).
///
/// Takes an [AssetBundle] rather than using `rootBundle` directly so tests
/// can inject a fake bundle instead of relying on Flutter's asset pipeline
/// (mirrors [ContentLoader]'s reasoning).
class TracingLoader {
  const TracingLoader(this._bundle);

  final AssetBundle _bundle;

  Future<TracingContent> loadLetters() async {
    final raw = await _bundle.loadString('assets/content/tracing/letters.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return TracingContent.fromJson(json);
  }

  Future<TracingContent> loadNumbers() async {
    final raw = await _bundle.loadString('assets/content/tracing/numbers.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return TracingContent.fromJson(json);
  }

  /// Letters and numbers merged into one glyph map, since the tracing
  /// activity (queue, matcher, screen) treats any glyph id the same way
  /// regardless of which JSON file it came from.
  Future<TracingContent> loadAll() async {
    final letters = await loadLetters();
    final numbers = await loadNumbers();
    return TracingContent({...letters.glyphs, ...numbers.glyphs});
  }
}
