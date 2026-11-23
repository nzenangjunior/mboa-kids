import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/tracing/tracing_loader.dart';

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

const _lettersJson = '''
{
  "glyphs": {
    "A": { "strokes": [ [[0.5, 0.1], [0.2, 0.9]], [[0.5, 0.1], [0.8, 0.9]] ] },
    "B": { "strokes": [ [[0.3, 0.1], [0.3, 0.9]] ] }
  }
}
''';

void main() {
  test('loadLetters parses the glyph map with its strokes and points', () async {
    final loader = TracingLoader(
      _FakeAssetBundle({'assets/content/tracing/letters.json': _lettersJson}),
    );

    final content = await loader.loadLetters();

    expect(content.glyphs.keys, containsAll(['A', 'B']));
    final a = content['A']!;
    expect(a.strokes, hasLength(2));
    expect(a.strokes.first.points.first.x, 0.5);
    expect(a.strokes.first.points.first.y, 0.1);
    expect(a.strokes.first.points.last.x, 0.2);
  });

  test('a glyph with no tracing data returns null rather than throwing', () async {
    final loader = TracingLoader(
      _FakeAssetBundle({'assets/content/tracing/letters.json': _lettersJson}),
    );

    final content = await loader.loadLetters();

    expect(content['Z'], isNull);
  });
}
