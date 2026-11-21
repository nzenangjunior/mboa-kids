import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class DailyPathScreen extends StatelessWidget {
  const DailyPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go('/game'),
          child: const Text('Commencer', style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
