import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

/// Placeholder game screen; replaced by the real alphabet/numbers/vocabulary
/// games built in later steps (see CLAUDE.md section 10).
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/bravo'),
          child: const Text('Bonne réponse !', style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
