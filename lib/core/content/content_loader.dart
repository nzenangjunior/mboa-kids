import 'dart:convert';

import 'package:flutter/services.dart';

import 'models/alphabet_item.dart';
import 'models/number_item.dart';

/// Reads and parses the content JSON files under `assets/content/<world>/`.
///
/// Takes an [AssetBundle] rather than using `rootBundle` directly so tests
/// can inject a fake bundle instead of relying on Flutter's asset pipeline.
class ContentLoader {
  const ContentLoader(this._bundle);

  final AssetBundle _bundle;

  Future<AlphabetContent> loadAlphabet(String world) async {
    final json = await _loadJson('assets/content/$world/alphabet.json');
    return AlphabetContent.fromJson(json);
  }

  Future<NumbersContent> loadNumbers(String world) async {
    final json = await _loadJson('assets/content/$world/numbers.json');
    return NumbersContent.fromJson(json);
  }

  Future<Map<String, dynamic>> _loadJson(String path) async {
    final raw = await _bundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
