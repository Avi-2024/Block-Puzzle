import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game/puzzle.dart';
import 'game/puzzle_store.dart';
import 'ui/brand_splash.dart';
import 'ui/game_screen.dart';
import 'ui/puzzle_theme.dart';
import 'ui/tutorial_screen.dart';

Future<void> main() => launch();

Future<void> launch({bool autoPlay = false}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080D34),
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

class PuzzleApp extends StatefulWidget {
  const PuzzleApp({
    super.key,
    required this.engine,
    required this.initialState,
    this.store,
    this.autoPlay = false,
    this.showIntroduction,
    this.showBrandSplash = true,
  });
  final PuzzleEngine engine;
  final PuzzleState initialState;
  final PuzzleStore? store;
  final bool autoPlay;
  final bool? showIntroduction;
  final bool showBrandSplash;
  @override
  State<PuzzleApp> createState() => _PuzzleAppState();
}

class _PuzzleAppState extends State<PuzzleApp> {
  late PuzzlePalette _palette;
  late bool _intro;
  late bool _showBrandSplash;
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  @override
  void initState() {
    super.initState();
    _palette = PuzzlePalette.fromId(widget.store?.theme);
    _showBrandSplash = widget.showBrandSplash;
    _intro =
        widget.showIntroduction ??
        (widget.store != null &&
            !widget.store!.tutorialCompleted &&
            widget.initialState.moves == 0 &&
            !widget.autoPlay);
  }

  Future<void> _theme(PuzzlePalette palette) async {
    await widget.store?.setTheme(palette.id);
    if (mounted) setState(() => _palette = palette);
  }

  Future<void> _completeIntro() async {
    setState(() => _intro = false);
    try {
      await widget.store?.completeTutorial();
    } catch (_) {
      _messenger.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'You can play, but the introduction preference could not be saved.',
          ),
        ),
      );
    }
  }

  void _finishBrandSplash() {
    if (mounted) setState(() => _showBrandSplash = false);
  }

  @override
  Widget build(BuildContext context) => PuzzleTheme(
    palette: _palette,
    onChanged: _theme,
    child: MaterialApp(
      title: 'Magic Blocks: Combo Puzzle',
      scaffoldMessengerKey: _messenger,
      debugShowCheckedModeBanner: false,
      theme: _palette.themeData,
      home: _showBrandSplash
          ? BrandSplash(onFinished: _finishBrandSplash)
          : _intro
          ? TutorialScreen(
              onComplete: _completeIntro,
              reduceMotion: widget.store?.reduceMotion ?? false,
            )
          : GameScreen(
              engine: widget.engine,
              initialState: widget.initialState,
              store: widget.store,
              autoPlay: widget.autoPlay,
            ),
    ),
  );
}
