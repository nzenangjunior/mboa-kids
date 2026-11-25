// Tests FlutterTtsSpeechEngine's locale-resolution logic (CLAUDE.md
// section 6: a wrong-accent voice beats silence for a child who can't
// read) by intercepting flutter_tts's own platform channel and scripting
// which locales it reports as available, instead of mocking SpeechEngine
// itself (that fake lives in tts_fallback_audio_service_test.dart and
// tests a different layer: TtsFallbackAudioService's own text mapping).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/audio/speech_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_tts');
  late Set<String> availableLocales;
  late List<MethodCall> calls;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          switch (call.method) {
            case 'isLanguageAvailable':
              // Mirrors flutter_tts's own contract (see its web backend):
              // a bare language code with no region ("en") matches any
              // installed locale sharing that language prefix.
              final requested = call.arguments as String;
              if (requested.contains('-')) {
                return availableLocales.contains(requested);
              }
              return availableLocales.any(
                (locale) => locale.split('-').first.toLowerCase() == requested.toLowerCase(),
              );
            case 'getVoices':
              // Non-empty so _ensureVoicesLoaded's poll resolves immediately.
              return [
                for (final locale in availableLocales) {'name': locale, 'locale': locale},
              ];
            case 'setLanguage':
            case 'awaitSpeakCompletion':
            case 'speak':
            case 'stop':
              return 1;
          }
          return null;
        });
  }

  setUp(() {
    calls = [];
    availableLocales = {};
    install();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('resolveLocale (CLAUDE.md section 6: accent fallback, silence last)', () {
    test('resolves to the exact requested locale when it is installed', () async {
      availableLocales = {'en-GB'};
      final engine = FlutterTtsSpeechEngine();

      expect(await engine.resolveLocale('en-GB'), 'en-GB');
    });

    test(
      'falls back to any other voice in the same language when the exact one is missing',
      () async {
        availableLocales = {'en-US'};
        final engine = FlutterTtsSpeechEngine();

        expect(await engine.resolveLocale('en-GB'), 'en');
      },
    );

    test('resolves to null (silence) only when nothing in that language exists', () async {
      availableLocales = {'fr-FR'};
      final engine = FlutterTtsSpeechEngine();

      expect(await engine.resolveLocale('en-GB'), isNull);
    });

    test('is resolved once per requested locale, never re-queried', () async {
      availableLocales = {'en-US'};
      final engine = FlutterTtsSpeechEngine();

      await engine.resolveLocale('en-GB');
      calls.clear();
      await engine.resolveLocale('en-GB');

      expect(
        calls.where((c) => c.method == 'isLanguageAvailable'),
        isEmpty,
        reason: 'a second resolution of the same locale must use the cache',
      );
    });
  });

  group('speak uses the resolved locale', () {
    test('speaks using a same-language fallback voice instead of staying silent', () async {
      availableLocales = {'en-US'};
      final engine = FlutterTtsSpeechEngine();

      await engine.speak('Touch the letter B', locale: 'en-GB');

      final setLanguageCalls = calls.where((c) => c.method == 'setLanguage').toList();
      expect(setLanguageCalls, hasLength(1));
      expect(setLanguageCalls.single.arguments, 'en');
      expect(calls.where((c) => c.method == 'speak'), hasLength(1));
    });

    test('never calls speak() when nothing in the requested language exists', () async {
      availableLocales = {'fr-FR'};
      final engine = FlutterTtsSpeechEngine();

      await engine.speak('Touch the letter B', locale: 'en-GB');

      expect(calls.where((c) => c.method == 'speak'), isEmpty);
    });
  });
}
