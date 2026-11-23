import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Mboa Kids ABC & 123',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/world'),
                  child: const Text('Jouer', style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ),
          // Temporary placement, icon-only (no text for the child); the
          // real home screen layout comes at the Finition step.
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              iconSize: 48,
              onPressed: () => context.go('/album'),
              icon: const Icon(Icons.star, color: MboaKidsTheme.pink),
            ),
          ),
          // Temporary too: tracing isn't part of the daily path yet (that's
          // étape 10), so it needs its own way in for now, same as the
          // album above. Reuses whichever world was last selected.
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              iconSize: 48,
              onPressed: () => context.go('/tracing'),
              icon: const Icon(Icons.edit, color: MboaKidsTheme.purple),
            ),
          ),
        ],
      ),
    );
  }
}
