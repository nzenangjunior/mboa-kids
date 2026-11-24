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
    required ClipPlayer sfxPlayer,
    required AudioService fallback,
    required Map<String, String> itemAudioPaths,
    required Map<String, String> promptAudioPaths,
    required Map<String, String> sfxAudioPaths,
    List<String> praiseAudioPaths = const [],
    Random? random,
    void Function(String missingId)? onMissingClip,
  }) : _player = player,
       _sfxPlayer = sfxPlayer,
       _fallback = fallback,
       _itemAudioPaths = itemAudioPaths,
       _promptAudioPaths = promptAudioPaths,
       _sfxAudioPaths = sfxAudioPaths,
       _praiseAudioPaths = praiseAudioPaths,
       _random = random ?? Random(),
       _onMissingClip = onMissingClip ?? _logMissingClip;

  final ClipPlayer _player;

  /// A player of its own, never shared with spoken instructions
  /// (CLAUDE.md section 10): a sound effect must never wait behind a
  /// slow or missing voice clip still loading on [_player] — reproduced
  /// live, where a single shared player made the wrong-answer sound
  /// arrive several seconds late, queued behind the retry instruction's
  /// own failing clip loads.
  final ClipPlayer _sfxPlayer;

  final AudioService _fallback;
  final Map<String, String> _itemAudioPaths;
  final Map<String, String> _promptAudioPaths;
  final Map<String, String> _sfxAudioPaths;
  final List<String> _praiseAudioPaths;
  final Random _random;
  final void Function(String missingId) _onMissingClip;

  @override
  Future<void> playItem(String itemId) =>
      _playOrFallback(_itemAudioPaths[itemId], itemId, () => _fallback.playItem(itemId), _player);

  @override
  Future<void> playPrompt(String key) =>
      _playOrFallback(_promptAudioPaths[key], key, () => _fallback.playPrompt(key), _player);

  @override
  Future<void> playInstruction({required String promptKey, required String itemId}) async {
    final promptPath = _promptAudioPaths[promptKey];
    final itemPath = _itemAudioPaths[itemId];
    final id = 'instruction:$promptKey+$itemId';
    // Both clips must exist and actually play — a half-clip-half-TTS
    // instruction would be its own kind of "two separate phrases", so
    // any failure falls back to the single combined TTS utterance
    // instead, rather than mixing a successful clip with a fallback for
    // just the other half.
    if (promptPath != null &&
        itemPath != null &&
        await _tryPlay(promptPath, _player) &&
        await _tryPlay(itemPath, _player)) {
      return;
    }
    _onMissingClip(id);
    await _fallback.playInstruction(promptKey: promptKey, itemId: itemId);
  }

  @override
  Future<void> playSfx(String name) =>
      _playOrFallback(_sfxAudioPaths[name], name, () => _fallback.playSfx(name), _sfxPlayer);

  @override
  Future<void> playPraise() async {
    if (_praiseAudioPaths.isEmpty) {
      _onMissingClip('praise');
      return _fallback.playPraise();
    }
    final path = _praiseAudioPaths[_random.nextInt(_praiseAudioPaths.length)];
    if (!await _tryPlay(path, _player)) {
      _onMissingClip('praise:$path');
      await _fallback.playPraise();
    }
  }

  Future<void> _playOrFallback(
    String? assetPath,
    String id,
    Future<void> Function() runFallback,
    ClipPlayer player,
  ) async {
    if (assetPath == null || !await _tryPlay(assetPath, player)) {
      _onMissingClip(id);
      await runFallback();
    }
  }

  Future<bool> _tryPlay(String assetPath, ClipPlayer player) async {
    try {
      await player.playAsset(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _sfxPlayer.stop();
    await _fallback.stop();
  }

  static void _logMissingClip(String missingId) {
    developer.log('Missing audio clip, falling back to TTS: $missingId', name: 'AudioService');
  }
}
