import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// One "fin de partie" sticker (CLAUDE.md section 8): a small reward
/// given for finishing any game, regardless of score — distinct from the
/// golden letter stickers, which are rarer and only earned on `acquis`.
/// Real artwork can replace [emoji] later without any code change, same
/// as the audio clips (CLAUDE.md section 6).
class GameSticker {
  const GameSticker({required this.id, required this.emoji});

  final String id;
  final String emoji;

  factory GameSticker.fromJson(Map<String, dynamic> json) {
    return GameSticker(id: json['id'] as String, emoji: json['emoji'] as String);
  }
}

/// Loads the sticker list from `assets/content/stickers.json` (CLAUDE.md
/// section 9: content lives in JSON, never hardcoded).
class StickerCatalog {
  StickerCatalog(this._bundle);

  final AssetBundle _bundle;

  Future<List<GameSticker>> load() async {
    final raw = await _bundle.loadString('assets/content/stickers.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final items = json['stickers'] as List<dynamic>;
    return items
        .map((item) => GameSticker.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}

GameSticker pickRandomSticker(List<GameSticker> catalog, Random random) {
  return catalog[random.nextInt(catalog.length)];
}
