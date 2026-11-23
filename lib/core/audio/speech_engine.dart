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
  bool _awaitCompletionSet = false;
  Future<void> _queue = Future<void>.value();

  /// Different screens call [speak] from independent async chains (e.g. the
  /// wrong-answer feedback and, a second later, the next round's prompt)
  /// without awaiting each other. [_ensureAwaitsCompletion] only stops a
  /// *single* caller from moving on before its own utterance finishes; it
  /// does nothing to stop a second, unrelated caller from starting a new
  /// utterance while the first is still in flight. On the web, that overlap
  /// makes `speechSynthesis` interrupt the first utterance while it's still
  /// dispatching word-boundary events for it, which then read a `charIndex`
  /// out of range for the new text and throw (see the comment below). So
  /// every call is chained onto [_queue] here, regardless of call site, to
  /// guarantee true one-at-a-time playback.
  @override
  Future<void> speak(String text, {required String locale}) {
    final result = _queue.then((_) => _speakNow(text, locale));
    _queue = result.catchError((_) {});
    return result;
  }

  Future<void> _speakNow(String text, String locale) async {
    await _ensureVoicesLoaded();
    await _ensureAwaitsCompletion();

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

  /// flutter_tts reuses a single native utterance object instead of
  /// creating one per call. Without this, `speak()` returns before the
  /// utterance actually finishes, so back-to-back calls (prompt, then the
  /// letter) overwrite its text while the browser is still dispatching
  /// word-boundary events for the previous one — those then read a
  /// `charIndex` that is out of range for the new (often much shorter)
  /// text and throw a `RangeError` from inside flutter_tts's web plugin.
  /// Waiting for completion serializes our calls and avoids that race.
  Future<void> _ensureAwaitsCompletion() async {
    if (_awaitCompletionSet) return;
    _awaitCompletionSet = true;
    await _tts.awaitSpeakCompletion(true);
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
