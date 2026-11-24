import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mboa_kids/app/providers.dart';
import 'package:mboa_kids/core/audio/audio_service.dart';
import 'package:mboa_kids/core/content/content_loader.dart';
import 'package:mboa_kids/core/progress/drift_progress_repository.dart';
import 'package:mboa_kids/core/progress/progress_database.dart';
import 'package:mboa_kids/core/progress/item_state.dart';
import 'package:mboa_kids/features/alphabet/alphabet_game_screen.dart';
import 'package:mboa_kids/features/islands/level_path_screen.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final content = files[key];
    if (content == null) throw FlutterError('Asset not found: $key');
    return ByteData.view(Uint8List.fromList(utf8.encode(content)).buffer);
  }
}

class _FakeAudioService implements AudioService {
  @override
  Future<void> playItem(String itemId) async {}
  @override
  Future<void> playPrompt(String key) async {}
  @override
  Future<void> playSfx(String name) async {}
  @override
  Future<void> playPraise() async {}
  @override
  Future<void> stop() async {}
}

String _letter(String glyph) => '''
{ "id": "fr.letter.$glyph", "glyph": "$glyph", "lower": "${glyph.toLowerCase()}",
  "audio": "audio/fr/letters/${glyph.toLowerCase()}.ogg",
  "word": { "label": "mot", "image": "images/mot.webp", "audio": "audio/mot.ogg" } }
''';

// 6 letters, packSize 3: pack1 = A,B,C (always open from the start, since
// there is no French start set), pack2 = D,E,F (locked until pack1 is
// acquis).
final _alphabetJson = '''
{ "world": "fr", "module": "alphabet", "packSize": 3,
  "items": [${['A', 'B', 'C', 'D', 'E', 'F'].map(_letter).join(',')}] }
''';

const _numbersJson = '''
{"world": "fr", "recognize": [[0, 20]], "countObjectsMax": 20, "writeMax": 0, "countByTensMax": 100}
''';

void main() {
  testWidgets('pack 1 is open and tappable, pack 2 is locked', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldProvider.overrideWith((ref) => 'fr'),
          contentLoaderProvider.overrideWithValue(
            ContentLoader(
              _FakeAssetBundle({
                'assets/content/fr/alphabet.json': _alphabetJson,
                'assets/content/fr/numbers.json': _numbersJson,
              }),
            ),
          ),
          audioServiceProvider('fr').overrideWith((ref) async => _FakeAudioService()),
          progressRepositoryProvider.overrideWithValue(
            DriftProgressRepository(ProgressDatabase(NativeDatabase.memory())),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const LevelPathScreen(islandType: IslandType.alphabet),
              ),
              GoRoute(
                path: '/game',
                builder: (context, state) =>
                    AlphabetGameScreen(packNumber: state.extra as int?),
              ),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byIcon(Icons.lock), findsOneWidget, reason: 'only pack 2 is locked');
    expect(find.text('A B C'), findsOneWidget);
    expect(find.text('D E F'), findsNothing, reason: 'a locked level shows a lock, not its glyphs');

    await tester.tap(find.text('A B C'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      find.byType(AlphabetGameScreen),
      findsOneWidget,
      reason: 'tapping the open level launches its game',
    );
  });

  testWidgets('a pack fully acquis shows as done, with its best stars', (
    WidgetTester tester,
  ) async {
    final db = ProgressDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftProgressRepository(db);
    for (final glyph in ['A', 'B', 'C']) {
      await repository.seed('fr.letter.$glyph', ItemState.acquis);
    }
    await repository.recordLevelStars('fr.alphabet.pack1', 2);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worldProvider.overrideWith((ref) => 'fr'),
          contentLoaderProvider.overrideWithValue(
            ContentLoader(
              _FakeAssetBundle({
                'assets/content/fr/alphabet.json': _alphabetJson,
                'assets/content/fr/numbers.json': _numbersJson,
              }),
            ),
          ),
          audioServiceProvider('fr').overrideWith((ref) async => _FakeAudioService()),
          progressRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const LevelPathScreen(islandType: IslandType.alphabet),
              ),
            ],
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byIcon(Icons.star), findsNWidgets(2));
    expect(find.byIcon(Icons.star_border), findsNWidgets(1));
    expect(
      find.byIcon(Icons.lock),
      findsNothing,
      reason: 'pack 2 is now open: pack 1 is fully acquis',
    );
  });
}
