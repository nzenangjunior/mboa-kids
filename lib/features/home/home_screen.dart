import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/audio/audio_service.dart';
import '../../shared/widgets/baobab.dart';
import '../../shared/widgets/long_press_hold.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/pagne_pattern.dart';
import '../../shared/widgets/speech_bubble.dart';
import 'parent_gate_dialog.dart';

/// The home screen (CLAUDE.md section 10): a small scene (sky, ground,
/// baobab) with the mascot, a big ▶ button into the daily path, a way
/// into the island map and the album, and the two world flags — the only
/// place the world is chosen, remembered across launches. No text for
/// the child anywhere here.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AudioService? _audio;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _restoreLastWorld();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPrompt());
  }

  @override
  void dispose() {
    unawaited(_audio?.stop());
    super.dispose();
  }

  /// CLAUDE.md section 10: "le monde choisi est mémorisé" — applied once,
  /// here, rather than baking persistence into [worldProvider] itself
  /// (which stays a simple in-memory default for everything downstream).
  Future<void> _restoreLastWorld() async {
    try {
      final repository = ref.read(progressRepositoryProvider);
      final lastWorld = await repository.lastWorld();
      if (lastWorld != null && mounted) {
        ref.read(worldProvider.notifier).state = lastWorld;
      }
    } catch (_) {
      // Keep whatever worldProvider's own default already is.
    }
  }

  Future<void> _playPrompt() async {
    if (mounted) setState(() => _speaking = true);
    try {
      final world = ref.read(worldProvider);
      final audio = await ref.read(audioServiceProvider(world).future);
      _audio = audio;
      await audio.playPrompt('home_screen');
    } catch (_) {
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  Future<void> _chooseWorld(String world) async {
    ref.read(worldProvider.notifier).state = world;
    unawaited(ref.read(progressRepositoryProvider).setLastWorld(world));
    unawaited(_playPrompt());
  }

  Future<void> _onBaobabTap() async {
    try {
      final world = ref.read(worldProvider);
      final audio = await ref.read(audioServiceProvider(world).future);
      await audio.playSfx('baobab');
    } catch (_) {}
  }

  Future<void> _onParentLockHeld() async {
    final granted = await showDialog<bool>(
      context: context,
      builder: (_) => const ParentGateDialog(),
    );
    if (granted == true && mounted) context.go('/debug/progress');
  }

  @override
  Widget build(BuildContext context) {
    final world = ref.watch(worldProvider);
    final hasNewSticker = ref.watch(albumHasNewStickerProvider).value ?? false;

    return Scaffold(
      body: Stack(
        children: [
          const _SkyAndGround(),
          const Positioned.fill(child: PagnePattern(color: MboaKidsTheme.terracotta)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _WorldFlag(
                      emoji: '🇫🇷',
                      selected: world == 'fr',
                      onTap: () => _chooseWorld('fr'),
                    ),
                    const SizedBox(width: 24),
                    _WorldFlag(
                      emoji: '🇬🇧',
                      selected: world == 'en',
                      onTap: () => _chooseWorld('en'),
                    ),
                  ],
                ),
                Expanded(
                  // SizedBox.expand: a Stack given loose constraints sizes
                  // itself to its only non-positioned child (the narrow
                  // mascot/button column) — collapsing to ~150px wide and
                  // centering that, which left the Positioned baobab
                  // measured against that narrow box instead of the full
                  // scene width. This forces the Stack to the full
                  // available size so left/bottom are relative to it.
                  child: SizedBox.expand(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          left: 24,
                          bottom: 0,
                          child: Baobab(onTap: _onBaobabTap, height: 200),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SpeechBubble(visible: _speaking),
                            const SizedBox(height: 4),
                            Mascot(
                              mood: _speaking ? MascotMood.happy : MascotMood.idle,
                              onTap: _playPrompt,
                            ),
                            const SizedBox(height: 40),
                            _BigPlayButton(onTap: () => context.go('/daily-path')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LongPressHold(
                        onHeld: _onParentLockHeld,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.lock_outline, color: Colors.white70, size: 28),
                        ),
                      ),
                      IconButton(
                        iconSize: 48,
                        onPressed: () => context.go('/islands'),
                        icon: const Icon(Icons.map, color: MboaKidsTheme.purple),
                      ),
                      _AlbumButton(hasNew: hasNewSticker, onTap: () => context.go('/album')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkyAndGround extends StatelessWidget {
  const _SkyAndGround();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [MboaKidsTheme.lightPurple, MboaKidsTheme.skyWarm],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [MboaKidsTheme.groundWarm, MboaKidsTheme.terracotta],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorldFlag extends StatelessWidget {
  const _WorldFlag({required this.emoji, required this.selected, required this.onTap});

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? MboaKidsTheme.lightPink : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MboaKidsTheme.pink, width: 3),
                )
              : null,
          child: Text(emoji, style: const TextStyle(fontSize: 36)),
        ),
      ),
    );
  }
}

class _BigPlayButton extends StatelessWidget {
  const _BigPlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MboaKidsTheme.pink,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 140,
          height: 140,
          child: Icon(Icons.play_arrow, size: 96, color: Colors.white),
        ),
      ),
    );
  }
}

class _AlbumButton extends StatelessWidget {
  const _AlbumButton({required this.hasNew, required this.onTap});

  final bool hasNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          iconSize: 48,
          onPressed: onTap,
          icon: const Icon(Icons.auto_stories, color: MboaKidsTheme.purple),
        ),
        if (hasNew)
          const Positioned(
            top: 4,
            right: 4,
            child: _Dot(),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(color: MboaKidsTheme.gold, shape: BoxShape.circle),
    );
  }
}
