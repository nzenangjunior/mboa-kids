import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class BravoScreen extends StatelessWidget {
  const BravoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bravo ! ⭐⭐⭐',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Accueil', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
