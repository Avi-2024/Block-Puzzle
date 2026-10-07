import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/puzzle.dart';
import 'game/puzzle_store.dart';
import 'ui/game_screen.dart';

Future<void> main() => launch();

Future<void> launch({bool autoPlay = false}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF19385F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  PuzzleStore? store;
  try {
    store = PuzzleStore(await SharedPreferences.getInstance());
  } catch (error) {
    debugPrint('Local progress storage unavailable: $error');
  }
  final engine = PuzzleEngine();
  runApp(
    PuzzleApp(
      engine: engine,
      store: store,
      initialState: store?.load(engine) ?? engine.fresh(),
      autoPlay: autoPlay,
    ),
  );
}

class PuzzleApp extends StatelessWidget {
  const PuzzleApp({
    super.key,
    required this.engine,
    required this.initialState,
    this.store,
    this.autoPlay = false,
  });
  final PuzzleEngine engine;
  final PuzzleState initialState;
  final PuzzleStore? store;
  final bool autoPlay;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Block Puzzle Preview',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF65BFA4),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF19385F),
      useMaterial3: true,
    ),
    home: GameScreen(
      engine: engine,
      initialState: initialState,
      store: store,
      autoPlay: autoPlay,
    ),
  );
}
