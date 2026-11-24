import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/audio/audio_service.dart';
import '../../shared/widgets/home_button.dart';
import '../../shared/widgets/mascot.dart';

/// Shown instead of starting the tracing half of the daily path when the
/// session duration has run out (CLAUDE.md section 7: "la séance s'arrête
/// à la durée choisie... après le jeu en cours → écran « la mascotte
/// dort »"). The alphabet round just played still gets its own Bravo
/// first — nothing earned is ever hidden — this screen only replaces
/// starting a second activity.
class MascotSleepingScreen extends ConsumerStatefulWidget {
  const MascotSleepingScreen({super.key});

  @override
  ConsumerState<MascotSleepingScreen> createState() => _MascotSleepingScreenState();
}

class _MascotSleepingScreenState extends ConsumerState<MascotSleepingScreen> {
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
      await audio.playPrompt('mascot_sleeping');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(child: Mascot(mood: MascotMood.asleep, size: 180, onTap: _playPrompt)),
            const Spacer(),
            Align(alignment: Alignment.bottomLeft, child: HomeButton()),
          ],
        ),
      ),
    );
  }
}
