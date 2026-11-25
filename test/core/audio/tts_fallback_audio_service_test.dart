import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/audio/speech_engine.dart';
import 'package:mboa_kids/core/audio/tts_fallback_audio_service.dart';

class _Spoken {
  _Spoken(this.text, this.locale);
  final String text;
  final String locale;
}

class _FakeSpeechEngine implements SpeechEngine {
  final List<_Spoken> calls = [];
  int stopCalls = 0;

  @override
  Future<void> speak(String text, {required String locale}) async {
    calls.add(_Spoken(text, locale));
  }

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<String?> resolveLocale(String requested) async => requested;
}

void main() {
  test('playItem speaks the mapped text in the given locale', () async {
    final engine = _FakeSpeechEngine();
    final service = TtsFallbackAudioService(
      speechEngine: engine,
      locale: 'en-GB',
      itemSpokenText: {'en.letter.A': 'A, as in apple'},
      promptSpokenText: const {},
    );

    await service.playItem('en.letter.A');

    expect(engine.calls, hasLength(1));
    expect(engine.calls.single.text, 'A, as in apple');
    expect(engine.calls.single.locale, 'en-GB');
  });

  test('playItem speaks the raw id when no mapping is registered', () async {
    final engine = _FakeSpeechEngine();
    final service = TtsFallbackAudioService(
      speechEngine: engine,
      locale: 'fr-FR',
      itemSpokenText: const {},
      promptSpokenText: const {},
    );

    await service.playItem('fr.number.7');

    expect(engine.calls.single.text, 'fr.number.7');
  });

  test('playPrompt speaks the mapped phrase', () async {
    final engine = _FakeSpeechEngine();
    final service = TtsFallbackAudioService(
      speechEngine: engine,
      locale: 'fr-FR',
      itemSpokenText: const {},
      promptSpokenText: {'tap_the_letter': 'Touche la lettre'},
    );

    await service.playPrompt('tap_the_letter');

    expect(engine.calls.single.text, 'Touche la lettre');
  });

  test('playPraise speaks the single configured phrase', () async {
    final engine = _FakeSpeechEngine();
    final service = TtsFallbackAudioService(
      speechEngine: engine,
      locale: 'fr-FR',
      itemSpokenText: const {},
      promptSpokenText: const {},
      praiseSpokenText: const ['Bravo Estrella !'],
    );

    await service.playPraise();

    expect(engine.calls.single.text, 'Bravo Estrella !');
  });

  test('stop stops the underlying speech engine', () async {
    final engine = _FakeSpeechEngine();
    final service = TtsFallbackAudioService(
      speechEngine: engine,
      locale: 'fr-FR',
      itemSpokenText: const {},
      promptSpokenText: const {},
    );

    await service.stop();

    expect(engine.stopCalls, 1);
  });

  test('playSfx never speaks anything', () async {
    final engine = _FakeSpeechEngine();
    final service = TtsFallbackAudioService(
      speechEngine: engine,
      locale: 'fr-FR',
      itemSpokenText: const {},
      promptSpokenText: const {},
    );

    await service.playSfx('success_chime');

    expect(engine.calls, isEmpty);
  });
}
