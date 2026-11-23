import 'package:just_audio/just_audio.dart';

/// Plays a single embedded audio asset. Narrow wrapper around the actual
/// player package so [ClipAudioService] can be unit tested with a fake.
abstract class ClipPlayer {
  /// Plays the asset at [assetPath] (relative to the Flutter asset root).
  /// Throws if the asset does not exist or fails to decode.
  Future<void> playAsset(String assetPath);

  /// Stops whatever clip is currently playing.
  Future<void> stop();
}

class JustAudioClipPlayer implements ClipPlayer {
  JustAudioClipPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> playAsset(String assetPath) async {
    await _player.setAsset('assets/$assetPath');
    await _player.play();
  }

  @override
  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
