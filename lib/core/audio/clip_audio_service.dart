// Initializing formals can't be used here: the fields are private but the
// constructor parameters must stay public so other files can call it.
// ignore_for_file: prefer_initializing_formals

import 'dart:developer' as developer;
import 'dart:math';

import 'audio_service.dart';
import 'clip_player.dart';

/// Plays embedded audio clips, falling back to [fallback] (normally a
/// [TtsFallbackAudioService]) and logging the missing id whenever the
/// requested clip isn't bundled yet. See CLAUDE.md section 6.
class ClipAudioService implements AudioService {
  ClipAudioService({
    required ClipPlayer player,
    required AudioService fallback,
    required Map<String, String> itemAudioPaths,
    required Map<String, String> promptAudioPaths,
    required Map<String, String> sfxAudioPaths,
    List<String> praiseAudioPaths = const [],
    Random? random,
    void Function(String missingId)? onMissingClip,
  }) : _player = player,
       _fallback = fallback,
       _itemAudioPaths = itemAudioPaths,
       _promptAudioPaths = promptAudioPaths,
       _sfxAudioPaths = sfxAudioPaths,
       _praiseAudioPaths = praiseAudioPaths,
       _random = random ?? Random(),
       _onMissingClip = onMissingClip ?? _logMissingClip;

  final ClipPlayer _player;
  final AudioService _fallback;
  final Map<String, String> _itemAudioPaths;
  final Map<String, String> _promptAudioPaths;
  final Map<String, String> _sfxAudioPaths;
  final List<String> _praiseAudioPaths;
  final Random _random;
  final void Function(String missingId) _onMissingClip;

  @override
  Future<void> playItem(String itemId) =>
      _playOrFallback(_itemAudioPaths[itemId], itemId, () => _fallback.playItem(itemId));

  @override
  Future<void> playPrompt(String key) =>
      _playOrFallback(_promptAudioPaths[key], key, () => _fallback.playPrompt(key));

  @override
  Future<void> playSfx(String name) =>
      _playOrFallback(_sfxAudioPaths[name], name, () => _fallback.playSfx(name));

  @override
  Future<void> playPraise() async {
    if (_praiseAudioPaths.isEmpty) {
      _onMissingClip('praise');
      return _fallback.playPraise();
    }
    final path = _praiseAudioPaths[_random.nextInt(_praiseAudioPaths.length)];
    if (!await _tryPlay(path)) {
      _onMissingClip('praise:$path');
      await _fallback.playPraise();
    }
  }

  Future<void> _playOrFallback(
    String? assetPath,
    String id,
    Future<void> Function() runFallback,
  ) async {
    if (assetPath == null || !await _tryPlay(assetPath)) {
      _onMissingClip(id);
      await runFallback();
    }
  }

  Future<bool> _tryPlay(String assetPath) async {
    try {
      await _player.playAsset(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _fallback.stop();
  }

  static void _logMissingClip(String missingId) {
    developer.log('Missing audio clip, falling back to TTS: $missingId', name: 'AudioService');
  }
}
