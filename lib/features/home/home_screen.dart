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
/// baobab) with the mascot beside the big ▶ button into the daily path, a
/// way into the island map and the album, and the two world flags — the
/// only place the world is chosen, remembered across launches. No text
/// for the child anywhere here.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AudioService? _audio;
  bool _speaking = false;
  bool _showPointingHint = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _restoreLastWorld();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playInitialPrompt());
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
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

  /// The very first time the home screen is ever shown, the mascot points
  /// at the ▶ button and says so, instead of the usual generic greeting
  /// (CLAUDE.md section 10, Refonte visuelle).
  Future<void> _playInitialPrompt() async {
    if (mounted) setState(() => _speaking = true);
    try {
      final world = ref.read(worldProvider);
      final audio = await ref.read(audioServiceProvider(world).future);
      _audio = audio;
      final repository = ref.read(progressRepositoryProvider);
      final alreadyShown = await repository.hasShownPlayHint();
      if (!alreadyShown) {
        if (mounted) setState(() => _showPointingHint = true);
        await audio.playPrompt('tap_big_button');
        unawaited(repository.setHasShownPlayHint(true));
        _hintTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showPointingHint = false);
        });
      } else {
        await audio.playPrompt('home_screen');
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _speaking = false);
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _CornerIconButton(
                            icon: Icons.map,
                            onTap: () => context.go('/islands'),
                          ),
                          const SizedBox(width: 8),
                          _AlbumButton(hasNew: hasNewSticker, onTap: () => context.go('/album')),
                        ],
                      ),
                      Row(
                        children: [
                          _WorldFlag(
                            emoji: '🇫🇷',
                            selected: world == 'fr',
                            onTap: () => _chooseWorld('fr'),
                          ),
                          const SizedBox(width: 8),
                          _WorldFlag(
                            emoji: '🇬🇧',
                            selected: world == 'en',
                            onTap: () => _chooseWorld('en'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  // SizedBox.expand: a Stack given loose constraints sizes
                  // itself to its only non-positioned child — collapsing
                  // to that child's own width and centering that, which
                  // left the Positioned baobab measured against a narrow
                  // box instead of the full scene width. This forces the
                  // Stack to the full available size so left/bottom are
                  // relative to it.
                  child: SizedBox.expand(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          left: 24,
                          bottom: 0,
                          child: Baobab(onTap: _onBaobabTap, height: 180),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SpeechBubble(visible: _speaking),
                                const SizedBox(height: 4),
                                Mascot(
                                  mood: _speaking ? MascotMood.happy : MascotMood.idle,
                                  onTap: _playPrompt,
                                ),
                              ],
                            ),
                            AnimatedOpacity(
                              opacity: _showPointingHint ? 1 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const _PointingHint(),
                            ),
                            _BigPlayButton(onTap: () => context.go('/daily-path')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: LongPressHold(
                    onHeld: _onParentLockHeld,
                    builder: (context, progress) => SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (progress > 0)
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 3,
                                color: Colors.white,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          const Icon(Icons.lock_outline, color: Colors.white70, size: 24),
                        ],
                      ),
                    ),
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

/// A chevron that nudges toward the ▶ button, shown only alongside the
/// home screen's first-visit hint (CLAUDE.md section 10, Refonte
/// visuelle: "en désignant le ▶").
class _PointingHint extends StatefulWidget {
  const _PointingHint();

  @override
  State<_PointingHint> createState() => _PointingHintState();
}

class _PointingHintState extends State<_PointingHint> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_controller.value * 10, 0), child: child),
      child: const Icon(Icons.chevron_right, size: 40, color: MboaKidsTheme.gold),
    );
  }
}

/// Smaller, frameless flags (CLAUDE.md section 10, Refonte visuelle:
/// "drapeaux plus petits en haut à droite, sans cadre") — the selected
/// one shown by scale/opacity alone, not a border.
class _WorldFlag extends StatelessWidget {
  const _WorldFlag({required this.emoji, required this.selected, required this.onTap});

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: MboaKidsTheme.minTapTarget,
        height: MboaKidsTheme.minTapTarget,
        child: Center(
          child: AnimatedScale(
            scale: selected ? 1.15 : 0.85,
            duration: const Duration(milliseconds: 150),
            child: AnimatedOpacity(
              opacity: selected ? 1 : 0.55,
              duration: const Duration(milliseconds: 150),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
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

class _CornerIconButton extends StatelessWidget {
  const _CornerIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 32,
      style: IconButton.styleFrom(
        minimumSize: const Size(MboaKidsTheme.minTapTarget, MboaKidsTheme.minTapTarget),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: MboaKidsTheme.purple),
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
        _CornerIconButton(icon: Icons.auto_stories, onTap: onTap),
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
