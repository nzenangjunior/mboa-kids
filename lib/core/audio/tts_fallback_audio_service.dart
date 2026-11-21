// Initializing formals can't be used here: the fields are private but the
// constructor parameters must stay public so other files can call it.
// ignore_for_file: prefer_initializing_formals

import 'dart:math';

import 'audio_service.dart';
import 'speech_engine.dart';

/// Speaks placeholder phrases with the device's TTS voice when a real
/// recorded clip is missing. Always used in `en-GB` or `fr-FR` (never any
/// other English accent, per CLAUDE.md section 2.7).
class TtsFallbackAudioService implements AudioService {
  TtsFallbackAudioService({
    required SpeechEngine speechEngine,
    required String locale,
    required Map<String, String> itemSpokenText,
    required Map<String, String> promptSpokenText,
    List<String> praiseSpokenText = const ['Bravo !'],
    Random? random,
  }) : _speechEngine = speechEngine,
       _locale = locale,
       _itemSpokenText = itemSpokenText,
       _promptSpokenText = promptSpokenText,
       _praiseSpokenText = praiseSpokenText,
       _random = random ?? Random();

  final SpeechEngine _speechEngine;
  final String _locale;
  final Map<String, String> _itemSpokenText;
  final Map<String, String> _promptSpokenText;
  final List<String> _praiseSpokenText;
  final Random _random;

  @override
  Future<void> playItem(String itemId) =>
      _speak(_itemSpokenText[itemId] ?? itemId);

  @override
  Future<void> playPrompt(String key) =>
      _speak(_promptSpokenText[key] ?? key);

  @override
  Future<void> playPraise() =>
      _speak(_praiseSpokenText[_random.nextInt(_praiseSpokenText.length)]);

  @override
  Future<void> playSfx(String name) async {
    // A non-speech sound effect has no meaningful spoken replacement.
  }

  Future<void> _speak(String text) =>
      _speechEngine.speak(text, locale: _locale);
}
