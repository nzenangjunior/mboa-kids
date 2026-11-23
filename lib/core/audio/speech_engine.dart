import 'package:flutter/foundation.dart';
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
  bool _voicesChecked = false;

  @override
  Future<void> speak(String text, {required String locale}) async {
    await _ensureVoicesLoaded();

    if (_currentLocale != locale) {
      final available = await _tts.isLanguageAvailable(locale);
      if (available != true) {
        debugPrint(
          '[AudioService] Aucune voix TTS "$locale" trouvée sur cet '
          'appareil/navigateur ; la voix par défaut sera utilisée.',
        );
      }
      await _tts.setLanguage(locale);
      _currentLocale = locale;
    }
    await _tts.speak(text);
  }

  /// Browsers load the `speechSynthesis` voice list asynchronously; the
  /// very first call can see an empty list and fail with a
  /// `SpeechSynthesisErrorEvent` if we speak (or select a language) before
  /// it's ready. flutter_tts's web binding does not wait for this itself,
  /// so we poll briefly here instead.
  Future<void> _ensureVoicesLoaded() async {
    if (_voicesChecked) return;
    _voicesChecked = true;

    for (var attempt = 0; attempt < 10; attempt++) {
      final voices = await _tts.getVoices;
      if (voices is List && voices.isNotEmpty) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    debugPrint(
      '[AudioService] Aucune voix TTS disponible après 1,5 s d\'attente : '
      'ce navigateur/appareil ne semble avoir aucun moteur de synthèse '
      'vocale installé.',
    );
  }
}
