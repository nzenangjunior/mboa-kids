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
import 'package:mboa_kids/core/progress/progress_repository.dart';
import 'package:mboa_kids/features/home/home_screen.dart';

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

const _alphabetJson = '''
{"world": "fr", "module": "alphabet", "packSize": 3, "items": []}
''';
const _numbersJson = '''
{"world": "fr", "recognize": [[0, 20]], "countObjectsMax": 20, "writeMax": 0, "countByTensMax": 100}
''';

Widget _buildTestApp({ProgressRepository? repository}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      contentLoaderProvider.overrideWithValue(
        ContentLoader(
          _FakeAssetBundle({
            'assets/content/fr/alphabet.json': _alphabetJson,
            'assets/content/fr/numbers.json': _numbersJson,
            'assets/content/en/alphabet.json': _alphabetJson,
            'assets/content/en/numbers.json': _numbersJson,
          }),
        ),
      ),
      audioServiceProvider('fr').overrideWith((ref) async => _FakeAudioService()),
      audioServiceProvider('en').overrideWith((ref) async => _FakeAudioService()),
      progressRepositoryProvider.overrideWithValue(
        repository ?? DriftProgressRepository(ProgressDatabase(NativeDatabase.memory())),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
      ),
    ),
  );
}

void main() {
  testWidgets('defaults to French when no world was ever chosen', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: _buildTestApp()),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(container.read(worldProvider), 'fr');
  });

  testWidgets('choosing a flag persists the world for next time', (WidgetTester tester) async {
    final db = ProgressDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftProgressRepository(db);

    await tester.pumpWidget(_buildTestApp(repository: repository));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('🇬🇧'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(await repository.lastWorld(), 'en');
  });

  testWidgets('a previously chosen world is restored on the next launch', (
    WidgetTester tester,
  ) async {
    final db = ProgressDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftProgressRepository(db);
    await repository.setLastWorld('en');

    final container = ProviderContainer(
      overrides: [
        contentLoaderProvider.overrideWithValue(
          ContentLoader(
            _FakeAssetBundle({
              'assets/content/fr/alphabet.json': _alphabetJson,
              'assets/content/fr/numbers.json': _numbersJson,
              'assets/content/en/alphabet.json': _alphabetJson,
              'assets/content/en/numbers.json': _numbersJson,
            }),
          ),
        ),
        audioServiceProvider('fr').overrideWith((ref) async => _FakeAudioService()),
        audioServiceProvider('en').overrideWith((ref) async => _FakeAudioService()),
        progressRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen())],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(container.read(worldProvider), 'en');
  });
}
