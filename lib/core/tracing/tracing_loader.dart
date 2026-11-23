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
}
