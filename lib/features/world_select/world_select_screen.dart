import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';

class WorldSelectScreen extends ConsumerWidget {
  const WorldSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _selectWorld(context, ref, 'fr'),
              child: const Text('Français', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 32),
            ElevatedButton(
              onPressed: () => _selectWorld(context, ref, 'en'),
              child: const Text('English', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }

  void _selectWorld(BuildContext context, WidgetRef ref, String world) {
    ref.read(worldProvider.notifier).state = world;
    context.go('/daily-path');
  }
}
