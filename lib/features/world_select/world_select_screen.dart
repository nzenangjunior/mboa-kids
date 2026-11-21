import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class WorldSelectScreen extends StatelessWidget {
  const WorldSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/daily-path'),
              child: const Text('Français', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 32),
            ElevatedButton(
              onPressed: () => context.go('/daily-path'),
              child: const Text('English', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
