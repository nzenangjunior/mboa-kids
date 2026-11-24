import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/audio/audio_service.dart';
import '../../shared/widgets/mascot_tap_target.dart';

/// The home screen (CLAUDE.md section 10): the mascot, a big ▶ button
/// into the daily path, a way into the island map, and the two world
/// flags — the only place the world is chosen, remembered across
/// launches. No text for the child anywhere here.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AudioService? _audio;

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
    try {
      final world = ref.read(worldProvider);
      final audio = await ref.read(audioServiceProvider(world).future);
      _audio = audio;
      await audio.playPrompt('home_screen');
    } catch (_) {}
  }

  Future<void> _chooseWorld(String world) async {
    ref.read(worldProvider.notifier).state = world;
    unawaited(ref.read(progressRepositoryProvider).setLastWorld(world));
    unawaited(_playPrompt());
  }

  @override
  Widget build(BuildContext context) {
    final world = ref.watch(worldProvider);

    return Scaffold(
      body: SafeArea(
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
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MascotTapTarget(onTap: _playPrompt),
                    const SizedBox(height: 40),
                    _BigPlayButton(onTap: () => context.go('/daily-path')),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IconButton(
                iconSize: 48,
                onPressed: () => context.go('/islands'),
                icon: const Icon(Icons.map, color: MboaKidsTheme.purple),
              ),
            ),
          ],
        ),
      ),
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
