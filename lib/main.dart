import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ProviderScope(child: MboaKidsApp()));
}

class MboaKidsApp extends StatelessWidget {
  const MboaKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mboa Kids ABC & 123',
      debugShowCheckedModeBanner: false,
      theme: MboaKidsTheme.theme,
      routerConfig: appRouter,
    );
  }
}
