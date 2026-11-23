import 'package:flutter_test/flutter_test.dart';
import 'package:mboa_kids/core/audio/audio_service.dart';
import 'package:mboa_kids/core/audio/clip_audio_service.dart';
import 'package:mboa_kids/core/audio/clip_player.dart';

class _FakeClipPlayer implements ClipPlayer {
  _FakeClipPlayer({this.failingPaths = const {}});

  final Set<String> failingPaths;
  final List<String> played = [];
  int stopCalls = 0;

  @override
  Future<void> playAsset(String assetPath) async {
    played.add(assetPath);
    if (failingPaths.contains(assetPath)) {
      throw Exception('missing asset: $assetPath');
    }
  }

  @override
  Future<void> stop() async => stopCalls++;
}

class _FakeAudioService implements AudioService {
  final List<String> itemCalls = [];
  final List<String> promptCalls = [];
  final List<String> sfxCalls = [];
  int praiseCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> playItem(String itemId) async => itemCalls.add(itemId);

  @override
  Future<void> playPrompt(String key) async => promptCalls.add(key);

  @override
  Future<void> playSfx(String name) async => sfxCalls.add(name);

  @override
  Future<void> playPraise() async => praiseCalls++;

  @override
  Future<void> stop() async => stopCalls++;
}

void main() {
  late _FakeAudioService fallback;
  final missingIds = <String>[];

  setUp(() {
    fallback = _FakeAudioService();
    missingIds.clear();
  });

  ClipAudioService buildService({
    required _FakeClipPlayer player,
    Map<String, String> itemAudioPaths = const {},
    Map<String, String> promptAudioPaths = const {},
    Map<String, String> sfxAudioPaths = const {},
    List<String> praiseAudioPaths = const [],
  }) {
    return ClipAudioService(
      player: player,
      fallback: fallback,
      itemAudioPaths: itemAudioPaths,
      promptAudioPaths: promptAudioPaths,
      sfxAudioPaths: sfxAudioPaths,
      praiseAudioPaths: praiseAudioPaths,
      onMissingClip: missingIds.add,
    );
  }

  test('playItem plays the clip when the asset is known and succeeds', () async {
    final player = _FakeClipPlayer();
    final service = buildService(
      player: player,
      itemAudioPaths: {'en.letter.A': 'audio/en/letters/a.ogg'},
    );

    await service.playItem('en.letter.A');

    expect(player.played, ['audio/en/letters/a.ogg']);
    expect(fallback.itemCalls, isEmpty);
    expect(missingIds, isEmpty);
  });

  test('playItem falls back and logs when the id is not registered', () async {
    final player = _FakeClipPlayer();
    final service = buildService(player: player);

    await service.playItem('en.letter.Z');

    expect(player.played, isEmpty);
    expect(fallback.itemCalls, ['en.letter.Z']);
    expect(missingIds, ['en.letter.Z']);
  });

  test('playItem falls back and logs when the clip fails to play', () async {
    final player = _FakeClipPlayer(failingPaths: {'audio/en/letters/a.ogg'});
    final service = buildService(
      player: player,
      itemAudioPaths: {'en.letter.A': 'audio/en/letters/a.ogg'},
    );

    await service.playItem('en.letter.A');

    expect(fallback.itemCalls, ['en.letter.A']);
    expect(missingIds, ['en.letter.A']);
  });

  test('playPrompt and playSfx follow the same fallback contract', () async {
    final player = _FakeClipPlayer();
    final service = buildService(player: player);

    await service.playPrompt('tap_the_letter');
    await service.playSfx('success_chime');

    expect(fallback.promptCalls, ['tap_the_letter']);
    expect(fallback.sfxCalls, ['success_chime']);
  });

  test('playPraise falls back when no praise clips are registered', () async {
    final player = _FakeClipPlayer();
    final service = buildService(player: player);

    await service.playPraise();

    expect(fallback.praiseCalls, 1);
    expect(missingIds, ['praise']);
  });

  test('playPraise plays a registered clip without falling back', () async {
    final player = _FakeClipPlayer();
    final service = buildService(
      player: player,
      praiseAudioPaths: ['audio/praise/bravo1.ogg'],
    );

    await service.playPraise();

    expect(player.played, ['audio/praise/bravo1.ogg']);
    expect(fallback.praiseCalls, 0);
  });
}
