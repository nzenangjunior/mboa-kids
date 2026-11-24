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
import 'package:mboa_kids/features/islands/island_map_screen.dart';
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
  Future<void> playInstruction({required String promptKey, required String itemId}) async {}
  @override
  Future<void> playSfx(String name) async {}
  @override
  Future<void> playPraise() async {}
  @override
  Future<void> stop() async {}
}

const _alphabetJson = '''
{"world": "fr", "module": "alphabet", "packSize": 3, "items": []}
''';
const _numbersJson = '''
{"world": "fr", "recognize": [[0, 20]], "countObjectsMax": 20, "writeMax": 0, "countByTensMax": 100}
''';

Widget _buildApp(Widget child) {
  return ProviderScope(
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
          GoRoute(path: '/', builder: (context, state) => child),
          GoRoute(
            path: '/islands/alphabet',
            builder: (context, state) =>
                const LevelPathScreen(islandType: IslandType.alphabet),
          ),
          GoRoute(
            path: '/islands/tracing',
            builder: (context, state) =>
                const LevelPathScreen(islandType: IslandType.tracing),
          ),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('shows 4 islands, no text anywhere on the screen', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(const IslandMapScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.abc), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.pin), findsOneWidget);
    expect(find.byIcon(Icons.image), findsOneWidget);
    // Nombres and Mots are locked.
    expect(find.byIcon(Icons.lock), findsNWidgets(2));
    expect(find.byType(Text), findsNothing, reason: 'CLAUDE.md: no text for the child');
  });

  testWidgets('tapping the open alphabet island opens its level path', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp(const IslandMapScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.abc));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(LevelPathScreen), findsOneWidget);
  });

  testWidgets('tapping a locked island does not navigate anywhere', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(const IslandMapScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.pin));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(IslandMapScreen), findsOneWidget);
  });
}
