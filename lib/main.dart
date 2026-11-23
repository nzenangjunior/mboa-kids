import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';

Future<void> main() async {
  // flutter_tts's web binding bare-prints the raw browser event on every
  // speechSynthesis error, including the harmless "interrupted"/"canceled"
  // ones fired whenever a new line of speech cuts off an earlier one (e.g.
  // retapping the mascot while it's still talking). Our own diagnostics
  // (speech_engine.dart) use debugPrint with a clear message instead, so
  // nothing useful is lost by filtering this one out.
  await runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    runApp(const ProviderScope(child: MboaKidsApp()));
  }, zoneSpecification: ZoneSpecification(
    print: (self, parent, zone, line) {
      if (line.contains('SpeechSynthesisErrorEvent')) return;
      parent.print(zone, line);
    },
  ));
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
