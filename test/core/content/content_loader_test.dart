import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/content/content_loader.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final content = files[key];
    if (content == null) {
      throw FlutterError('Asset not found: $key');
    }
    final bytes = utf8.encode(content);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

const _alphabetJson = '''
{
  "world": "en",
  "module": "alphabet",
  "packSize": 3,
  "items": [
    {
      "id": "en.letter.A",
      "glyph": "A",
      "lower": "a",
      "audio": "audio/en/letters/a.ogg",
      "word": { "label": "apple", "image": "images/vocab/apple.webp", "audio": "audio/en/words/apple.ogg" }
    },
    {
      "id": "en.letter.B",
      "glyph": "B",
      "lower": "b",
      "audio": "audio/en/letters/b.ogg",
      "word": { "label": "ball", "image": "images/vocab/ball.webp", "audio": "audio/en/words/ball.ogg" }
    }
  ]
}
''';

const _numbersJson = '''
{
  "world": "fr",
  "module": "numbers",
  "recognize": [[0, 20], [21, 50], [51, 100]],
  "countObjectsMax": 20,
  "writeMax": 20,
  "countByTensMax": 100
}
''';

void main() {
  late ContentLoader loader;

  setUp(() {
    loader = ContentLoader(
      _FakeAssetBundle({
        'assets/content/en/alphabet.json': _alphabetJson,
        'assets/content/fr/numbers.json': _numbersJson,
      }),
    );
  });

  group('loadAlphabet', () {
    test('parses world, packSize and items', () async {
      final content = await loader.loadAlphabet('en');

      expect(content.world, 'en');
      expect(content.packSize, 3);
      expect(content.items, hasLength(2));
    });

    test('parses each item including its word reference', () async {
      final content = await loader.loadAlphabet('en');
      final a = content.items.first;

      expect(a.id, 'en.letter.A');
      expect(a.glyph, 'A');
      expect(a.lower, 'a');
      expect(a.audio, 'audio/en/letters/a.ogg');
      expect(a.word.label, 'apple');
      expect(a.word.image, 'images/vocab/apple.webp');
      expect(a.word.audio, 'audio/en/words/apple.ogg');
    });

    test('throws when the asset is missing', () {
      expect(loader.loadAlphabet('de'), throwsA(isA<FlutterError>()));
    });
  });

  group('loadNumbers', () {
    test('parses tiers and configurable limits', () async {
      final content = await loader.loadNumbers('fr');

      expect(content.world, 'fr');
      expect(content.countObjectsMax, 20);
      expect(content.writeMax, 20);
      expect(content.countByTensMax, 100);
      expect(content.recognize, hasLength(3));
      expect(content.recognize.first.min, 0);
      expect(content.recognize.first.max, 20);
      expect(content.maxRecognizedValue, 100);
    });

    test('derives stable ids and audio paths for a tier', () async {
      final content = await loader.loadNumbers('fr');
      final firstTierItems = content.itemsInTier(content.recognize.first);

      expect(firstTierItems, hasLength(21)); // 0..20 inclusive
      expect(firstTierItems.first.id, 'fr.number.0');
      expect(firstTierItems.first.audio, 'audio/fr/numbers/0.ogg');
      expect(firstTierItems.last.id, 'fr.number.20');
    });
  });
}
