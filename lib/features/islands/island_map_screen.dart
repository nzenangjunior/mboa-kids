import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/audio/audio_service.dart';
import '../../shared/widgets/home_button.dart';
import '../../shared/widgets/mascot.dart';
import '../../shared/widgets/pagne_pattern.dart';

/// The 4 islands (CLAUDE.md section 10): Alphabet and Tracé are open now,
/// Nombres and Mots are shown locked (étapes 7-8, not built yet). No text
/// for the child — icon, color and the voice say which island is which.
class IslandMapScreen extends ConsumerStatefulWidget {
  const IslandMapScreen({super.key});

  @override
  ConsumerState<IslandMapScreen> createState() => _IslandMapScreenState();
}

class _IslandMapScreenState extends ConsumerState<IslandMapScreen> {
  AudioService? _audio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPrompt());
  }

  @override
  void dispose() {
    unawaited(_audio?.stop());
    super.dispose();
  }

  Future<void> _playPrompt() async {
    try {
      final world = ref.read(worldProvider);
      final audio = await ref.read(audioServiceProvider(world).future);
      _audio = audio;
      await audio.playPrompt('island_map');
    } catch (_) {
      // A missing or slow clip must never block the screen.
    }
  }

  Future<void> _onLocked() async {
    try {
      final world = ref.read(worldProvider);
      final audio = await ref.read(audioServiceProvider(world).future);
      _audio = audio;
      await audio.playPrompt('island_locked');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PagnePattern(color: MboaKidsTheme.terracotta)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Mascot(onTap: _playPrompt),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: [
                        _IslandCard(
                          icon: Icons.abc,
                          color: MboaKidsTheme.pink,
                          onTap: () => context.go('/islands/alphabet'),
                        ),
                        _IslandCard(
                          icon: Icons.edit,
                          color: MboaKidsTheme.purple,
                          onTap: () => context.go('/islands/tracing'),
                        ),
                        _IslandCard(
                          icon: Icons.pin,
                          color: Colors.orange,
                          locked: true,
                          onTap: _onLocked,
                        ),
                        _IslandCard(
                          icon: Icons.image,
                          color: Colors.teal,
                          locked: true,
                          onTap: _onLocked,
                        ),
                      ],
                    ),
                  ),
                ),
                const Align(alignment: Alignment.bottomLeft, child: HomeButton()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IslandCard extends StatelessWidget {
  const _IslandCard({
    required this.icon,
    required this.color,
    required this.onTap,
    this.locked = false,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: locked ? Colors.grey.shade300 : color,
      borderRadius: BorderRadius.circular(32),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 72, color: Colors.white),
              if (locked)
                const Positioned(
                  bottom: 16,
                  right: 16,
                  child: Icon(Icons.lock, size: 36, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
