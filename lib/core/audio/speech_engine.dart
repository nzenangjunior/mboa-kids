import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks text aloud using the device's voice. Dev-only fallback used
/// while real recorded clips are missing (CLAUDE.md section 6); narrow
/// wrapper so [TtsFallbackAudioService] can be unit tested with a fake.
abstract class SpeechEngine {
  Future<void> speak(String text, {required String locale});

  /// Stops the current utterance and drops anything still queued behind
  /// it. Called when the child leaves the screen that asked for speech, so
  /// a phrase that never reports completion (see [speak]'s doc) can't go
  /// on blocking every later call.
  Future<void> stop();

  /// Resolves which locale would actually be used to speak [requested]
  /// right now: [requested] itself if that exact voice is installed, any
  /// other voice in the same language if not (e.g. some `en-US` when
  /// `en-GB` is missing — CLAUDE.md section 6: a wrong accent is better
  /// than no voice at all for a child who can't read), or `null` if the
  /// device has no voice in that language at all, meaning [speak] will
  /// stay silent. Exposed so the parent debug panel can show the voice
  /// really in use, not just whether one exact locale is installed.
  Future<String?> resolveLocale(String requested);
}

class FlutterTtsSpeechEngine implements SpeechEngine {
  FlutterTtsSpeechEngine() : _tts = FlutterTts();

  /// How long [_speakNow] waits for a single utterance before giving up on
  /// it and letting the queue move on. The web `speechSynthesis` API can
  /// simply never fire a completion event for an utterance that was cut
  /// short (navigation, [stop]), and `awaitSpeakCompletion(true)` means
  /// `speak()` then never resolves on its own — without this timeout that
  /// one call would wedge every later call behind it forever.
  static const _speakTimeout = Duration(seconds: 4);

  final FlutterTts _tts;
  String? _currentLocale;
  bool _voicesChecked = false;
  bool _awaitCompletionSet = false;
  Future<void> _queue = Future<void>.value();

  /// Resolved once per requested locale, never again: a device/browser's
  /// installed voices aren't going to change mid-session, so there's no
  /// reason to re-query them (and pay [_speakTimeout]'s wait) on every
  /// single call after the first — reproduced live, where every failed
  /// instruction added a multi-second delay that compounded across a
  /// whole game. Maps the requested locale (e.g. "en-GB") to the locale
  /// to actually speak in, which may be a same-language fallback (e.g.
  /// "en"), or is absent from the map's keys until resolved, or maps to
  /// `null` if nothing in that language exists at all.
  final Map<String, String?> _resolvedLocale = {};

  /// Bumped by [stop]. A queued [_speakNow] call captures the generation it
  /// was queued under and checks it before doing anything observable, so a
  /// [stop] call effectively drops whatever was still waiting behind the
  /// utterance it interrupts, instead of letting it speak right after.
  int _generation = 0;

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
    final generation = _generation;
    final result = _queue.then((_) => _speakNow(text, locale, generation));
    _queue = result.catchError((_) {});
    return result;
  }

  Future<void> _speakNow(String text, String locale, int generation) async {
    if (generation != _generation) return;

    await _ensureVoicesLoaded();
    await _ensureAwaitsCompletion();
    if (generation != _generation) return;

    final resolved = await _resolveAndCache(locale);
    // Never wait on a language already known entirely absent: speak()/the
    // 4s timeout below exist for a voice that might still answer, not for
    // one that has already proven it won't.
    if (resolved == null) return;

    if (_currentLocale != resolved) {
      await _tts.setLanguage(resolved);
      _currentLocale = resolved;
    }
    if (generation != _generation) return;

    await _tts.speak(text).timeout(_speakTimeout, onTimeout: () => null);
  }

  @override
  Future<String?> resolveLocale(String requested) async {
    await _ensureVoicesLoaded();
    return _resolveAndCache(requested);
  }

  Future<String?> _resolveAndCache(String requested) async {
    if (_resolvedLocale.containsKey(requested)) {
      return _resolvedLocale[requested];
    }

    // CLAUDE.md section 6: a wrong-accent voice beats silence for a child
    // who can't read — try the exact locale first, then any other voice
    // in the same language, and only give up (speak() will then stay
    // silent) if the device has nothing in that language at all.
    String? resolved;
    if (await _tts.isLanguageAvailable(requested) == true) {
      resolved = requested;
    } else {
      final languagePrefix = requested.split('-').first;
      if (await _tts.isLanguageAvailable(languagePrefix) == true) {
        resolved = languagePrefix;
      }
    }

    _resolvedLocale[requested] = resolved;
    if (resolved == null) {
      debugPrint(
        '[AudioService] Aucune voix TTS pour la langue de "$requested" '
        'trouvée sur cet appareil/navigateur (ni exacte, ni dans la même '
        'langue) ; plus aucune tentative ne sera faite cette session (le '
        'jeu ne doit jamais attendre une voix absente).',
      );
    } else if (resolved != requested) {
      debugPrint(
        '[AudioService] Voix "$requested" absente ; repli sur une voix '
        '"$resolved" (même langue) plutôt que le silence.',
      );
    }
    return resolved;
  }

  /// Interrupts whatever is currently speaking and drops every utterance
  /// still queued behind it (CLAUDE.md section 2.6 "deux mondes jamais
  /// mélangés" relies on this too: leaving a world's game screen must not
  /// let its queued phrases bleed into the next screen).
  @override
  Future<void> stop() async {
    _generation++;
    _queue = Future<void>.value();
    await _tts.stop();
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
