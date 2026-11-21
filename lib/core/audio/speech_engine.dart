import 'package:flutter_tts/flutter_tts.dart';

/// Speaks text aloud using the device's voice. Dev-only fallback used
/// while real recorded clips are missing (CLAUDE.md section 6); narrow
/// wrapper so [TtsFallbackAudioService] can be unit tested with a fake.
abstract class SpeechEngine {
  Future<void> speak(String text, {required String locale});
}

class FlutterTtsSpeechEngine implements SpeechEngine {
  FlutterTtsSpeechEngine() : _tts = FlutterTts();

  final FlutterTts _tts;
  String? _currentLocale;

  @override
  Future<void> speak(String text, {required String locale}) async {
    if (_currentLocale != locale) {
      await _tts.setLanguage(locale);
      _currentLocale = locale;
    }
    await _tts.speak(text);
  }
}
