/// Plays the audio the child hears: spoken instructions, item names,
/// sound effects and praise. See CLAUDE.md section 6.
///
/// Every screen the child uses goes through this interface rather than
/// a concrete player, so [ClipAudioService] can fall back to
/// [TtsFallbackAudioService] transparently when a recorded clip is
/// missing.
abstract class AudioService {
  /// Plays a short spoken instruction, e.g. "touche la lettre A".
  Future<void> playPrompt(String key);

  /// Plays the clip naming a content item (a letter, a number, a word).
  Future<void> playItem(String itemId);

  /// Plays [promptKey] and [itemId] together as a single instruction —
  /// e.g. "touche la lettre A" — never as two separate utterances with a
  /// gap between them (CLAUDE.md section 10: "une consigne = une seule
  /// phrase"). Screens that announce "prompt, then which item" (the
  /// alphabet game, tracing) call this instead of [playPrompt] followed
  /// by [playItem].
  Future<void> playInstruction({required String promptKey, required String itemId});

  /// Plays a non-speech sound effect (success chime, soft error sound...).
  /// Never waits behind a spoken instruction still loading or failing to
  /// load — implementations must play it on its own channel/player, so a
  /// slow or missing voice clip can never delay the sound of an answer
  /// being right or wrong.
  Future<void> playSfx(String name);

  /// Plays a praise phrase, e.g. at the end of a game.
  Future<void> playPraise();

  /// Stops whatever is currently playing or queued. Called when the child
  /// leaves a screen, so no leftover clip or spoken phrase from that screen
  /// is still running (or blocking future calls) once a new one starts.
  Future<void> stop();
}
