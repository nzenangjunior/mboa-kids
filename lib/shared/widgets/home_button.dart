import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

/// A consistent way back to the home screen (CLAUDE.md section 10,
/// Refonte visuelle: "bouton maison pour revenir à l'accueil"), for
/// screens reached by tapping forward through the app rather than by a
/// back-navigable route (the island map, a level path) — the Android
/// back gesture alone isn't something a 4-year-old reliably knows to use.
class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 40,
      style: IconButton.styleFrom(
        minimumSize: const Size(MboaKidsTheme.minTapTarget, MboaKidsTheme.minTapTarget),
      ),
      onPressed: () => context.go('/'),
      icon: const Icon(Icons.home, color: MboaKidsTheme.purple),
    );
  }
}
