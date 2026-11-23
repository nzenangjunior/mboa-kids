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

  /// Plays a non-speech sound effect (success chime, soft error sound...).
  Future<void> playSfx(String name);

  /// Plays a praise phrase, e.g. at the end of a game.
  Future<void> playPraise();

  /// Stops whatever is currently playing or queued. Called when the child
  /// leaves a screen, so no leftover clip or spoken phrase from that screen
  /// is still running (or blocking future calls) once a new one starts.
  Future<void> stop();
}
