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
import 'package:mboa_kids/features/home/parent_gate_dialog.dart';

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
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/debug/progress',
            builder: (context, state) => const Scaffold(body: Text('DEBUG_MARKER')),
          ),
        ],
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

  group('parent gate (CLAUDE.md section 10: appui long de 2 s + calcul)', () {
    testWidgets('a quick tap on the lock does not open the gate', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ParentGateDialog), findsNothing);
    });

    testWidgets('holding the lock for 2 seconds opens the gate', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      final gesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.lock_outline)));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(ParentGateDialog), findsOneWidget);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('a correct answer opens the debug panel', (WidgetTester tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      final gesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.lock_outline)));
      await tester.pump(const Duration(seconds: 2));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      final question = tester.widget<Text>(find.textContaining('+')).data!;
      final numbers = RegExp(r'(\d+) \+ (\d+)').firstMatch(question)!;
      final correct = int.parse(numbers.group(1)!) + int.parse(numbers.group(2)!);

      await tester.tap(find.widgetWithText(ElevatedButton, '$correct'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('DEBUG_MARKER'), findsOneWidget);
    });

    testWidgets('a wrong answer closes the gate without navigating away', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pump(const Duration(milliseconds: 100));

      final gesture = await tester.startGesture(tester.getCenter(find.byIcon(Icons.lock_outline)));
      await tester.pump(const Duration(seconds: 2));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      final question = tester.widget<Text>(find.textContaining('+')).data!;
      final numbers = RegExp(r'(\d+) \+ (\d+)').firstMatch(question)!;
      final correct = int.parse(numbers.group(1)!) + int.parse(numbers.group(2)!);

      final wrongButton = tester
          .widgetList<ElevatedButton>(find.byType(ElevatedButton))
          .firstWhere((button) => (button.child as Text).data != '$correct');
      await tester.tap(find.byWidget(wrongButton));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ParentGateDialog), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('DEBUG_MARKER'), findsNothing);
    });
  });

  group('scene fills the screen at every window size (CLAUDE.md section 10, '
      'Refonte visuelle)', () {
    // The three sizes Louis actually tested with: a laptop window, a
    // smaller laptop window, and a phone held sideways — the narrowest and
    // (crucially) SHORTEST of the three, where a fixed-height baobab and a
    // big ▶ button have the least room to fit without overflowing.
    for (final size in [const Size(1411, 840), const Size(1280, 720), const Size(800, 360)]) {
      testWidgets('at ${size.width.toInt()}x${size.height.toInt()}', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(size);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_buildTestApp());
        await tester.pump(const Duration(milliseconds: 100));

        // No RenderFlex overflow or any other layout exception — this is
        // the one window size regressions actually show up at: the
        // baobab's fixed 180px height plus the header row and the lock
        // row leave the least slack in a short window.
        expect(tester.takeException(), isNull);

        // Regression check for the exact bug reproduced live: the sky/
        // ground gradients collapsing to zero width and only the
        // Scaffold's own flat background showing through.
        final skyAndGroundBoxes = tester
            .widgetList<DecoratedBox>(
              find.descendant(of: find.byType(HomeScreen), matching: find.byType(DecoratedBox)),
            )
            .toList();
        expect(skyAndGroundBoxes, isNotEmpty);
        for (final box in skyAndGroundBoxes) {
          final renderBox = tester
              .allElements
              .firstWhere((e) => e.widget == box)
              .renderObject! as RenderBox;
          expect(
            renderBox.size.width,
            size.width,
            reason: 'the sky/ground gradient must span the full width, not collapse to 0',
          );
        }

        // CLAUDE.md section 2.4: every tap target is at least 64dp, at
        // every window size — not just the ones Louis's own screen
        // happened to show full-size.
        for (final icon in [Icons.map, Icons.auto_stories]) {
          final buttonSize = tester.getSize(
            find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton)),
          );
          expect(buttonSize.width, greaterThanOrEqualTo(64));
          expect(buttonSize.height, greaterThanOrEqualTo(64));
        }
        for (final flag in ['🇫🇷', '🇬🇧']) {
          final flagTarget = tester.getSize(
            find.ancestor(of: find.text(flag), matching: find.byType(GestureDetector)),
          );
          expect(flagTarget.width, greaterThanOrEqualTo(64));
          expect(flagTarget.height, greaterThanOrEqualTo(64));
        }
      });
    }
  });
}
