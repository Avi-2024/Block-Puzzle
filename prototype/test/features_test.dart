import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle_prototype/game/puzzle.dart';
import 'package:puzzle_prototype/game/puzzle_store.dart';
import 'package:puzzle_prototype/main.dart';
import 'package:puzzle_prototype/ui/puzzle_theme.dart';
import 'package:puzzle_prototype/ui/puzzle_painters.dart';
import 'package:puzzle_prototype/ui/result_screen.dart';
import 'package:puzzle_prototype/ui/tutorial_screen.dart';
import 'game_screen_test.dart' show capture;

PuzzleState finished({bool record = true}) => PuzzleState(
  board: List<int>.filled(64, 0),
  tray: const [Piece(2, 1), null, null],
  score: 8640,
  best: record ? 8640 : 10000,
  maxCombo: 6,
  linesCleared: 42,
  startingBest: record ? 7200 : 10000,
  moves: 100,
);

void phone(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
}

void main() {
  setUpAll(() async {
    if (Platform.environment['PUZZLE_CAPTURE_UI'] == '1') {
      final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
      final loader = FontLoader('Roboto');
      for (final name in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']) {
        final font = File('${artifacts.path}/material_fonts/$name');
        if (await font.exists()) {
          loader.addFont(font.readAsBytes().then(ByteData.sublistView));
        }
      }
      await loader.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  test('sharing uses the actual round stats', () {
    expect(scoreShareText(finished()), contains('8,640'));
    expect(scoreShareText(finished()), contains('×6'));
    expect(scoreShareText(finished()), contains('42'));
    expect(scoreShareText(finished(record: false)), contains('10,000'));
  });
  for (final size in [const Size(320, 568), const Size(393, 852)]) {
    for (final p in PuzzlePalette.values) {
      testWidgets('result, theme choices and restart fit ${p.id} $size', (
        tester,
      ) async {
        phone(tester, size);
        SharedPreferences.setMockInitialValues({
          'puzzle.prototype.theme': p.id,
          'puzzle.prototype.tutorial': true,
        });
        final store = PuzzleStore(await SharedPreferences.getInstance()),
            key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: PuzzleApp(
              engine: PuzzleEngine(),
              initialState: finished(),
              store: store,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('NEW PERSONAL BEST'), findsOneWidget);
        expect(find.text('×6'), findsOneWidget);
        expect(find.text('42'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await capture(
          tester,
          key,
          'tilora-result-${p.id}-${size.width.toInt()}',
        );
        await tester.tap(find.byTooltip('Themes'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture(
          tester,
          key,
          'tilora-themes-${p.id}-${size.width.toInt()}',
        );
        await tester.tap(find.byTooltip('Close themes'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('play-again')));
        await tester.tap(find.byKey(const ValueKey('play-again')));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Score 0'), findsOneWidget);
        expect(store.load(PuzzleEngine()).best, 8640);
        expect(store.load(PuzzleEngine()).maxCombo, 0);
        expect(tester.takeException(), isNull);
        await capture(tester, key, 'tilora-game-${p.id}-${size.width.toInt()}');
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets(
    'theme draft cancels; apply updates gameplay and survives restart',
    (tester) async {
      phone(tester, const Size(393, 852));
      SharedPreferences.setMockInitialValues({
        'puzzle.prototype.tutorial': true,
      });
      final store = PuzzleStore(await SharedPreferences.getInstance());
      Future<void> settings() async {
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Themes'));
        await tester.pumpAndSettle();
      }

      Widget app() => PuzzleApp(
        engine: PuzzleEngine(),
        initialState: reviewScene(),
        store: store,
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await settings();
      await tester.tap(find.byKey(const ValueKey('theme-sand')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close themes'));
      await tester.pumpAndSettle();
      expect(store.theme, 'ocean');
      await settings();
      await tester.tap(find.byKey(const ValueKey('theme-midnight')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('apply-theme')));
      await tester.tap(find.byKey(const ValueKey('apply-theme')));
      await tester.pumpAndSettle();
      expect(store.theme, 'midnight');
      expect(find.bySemanticsLabel('Score 1280'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('puzzle-board')),
                  )
                  .painter!
              as PuzzleBoardPainter;
      expect(painter.palette, PuzzlePalette.midnight);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'first-game guide accepts drag and tap; persists once without altering progress',
    (tester) async {
      phone(tester, const Size(393, 852));
      SharedPreferences.setMockInitialValues({});
      final store = PuzzleStore(await SharedPreferences.getInstance());
      await store.save(reviewScene());
      final saved = store.preferences.getString(PuzzleStore.sessionKey),
          key = GlobalKey();
      Widget app({bool? intro}) => RepaintBoundary(
        key: key,
        child: PuzzleApp(
          engine: PuzzleEngine(),
          initialState: reviewScene(),
          store: store,
          showIntroduction: intro,
        ),
      );
      await tester.pumpWidget(app(intro: true));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('tutorial-next')))
            .onPressed,
        isNull,
      );
      await capture(tester, key, 'tilora-tutorial-drag');
      final start = tester.getCenter(
            find.byKey(const ValueKey('tutorial-piece')),
          ),
          end = tester.getCenter(find.byKey(const ValueKey('tutorial-target')));
      final gesture = await tester.startGesture(
        start,
        kind: ui.PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveTo(end);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Practice score 30'), findsOneWidget);
      for (var step = 1; step < 3; step++) {
        await tester.ensureVisible(find.byKey(const ValueKey('tutorial-next')));
        await tester.tap(find.byKey(const ValueKey('tutorial-next')));
        await tester.pumpAndSettle();
        await capture(
          tester,
          key,
          'tilora-tutorial-${step == 1 ? 'clear' : 'combo'}',
        );
        await tester.tap(find.byKey(const ValueKey('tutorial-piece')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('tutorial-target')));
        await tester.pumpAndSettle();
      }
      expect(find.bySemanticsLabel('Practice score 330'), findsOneWidget);
      await tester.ensureVisible(find.text('Start playing'));
      await tester.tap(find.text('Start playing'));
      await tester.pumpAndSettle();
      expect(store.tutorialCompleted, isTrue);
      expect(store.preferences.getString(PuzzleStore.sessionKey), saved);
      expect(find.bySemanticsLabel('Score 1280'), findsOneWidget);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('How to play'));
      await tester.pumpAndSettle();
      expect(find.text('A few good moves'), findsOneWidget);
      await tester.tap(find.text('Close guide'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Score 1280'), findsOneWidget);
      expect(store.preferences.getString(PuzzleStore.sessionKey), saved);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(TutorialScreen), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'small-screen intro skip is saved; nonrecord sharing copies real stats',
    (tester) async {
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          if (call.method == 'Clipboard.getData') return {'text': clipboard};
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      phone(tester, const Size(320, 568));
      SharedPreferences.setMockInitialValues({});
      final store = PuzzleStore(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        PuzzleApp(
          engine: PuzzleEngine(),
          initialState: PuzzleEngine().fresh(),
          store: store,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TutorialScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Skip intro'));
      await tester.pumpAndSettle();
      expect(store.tutorialCompleted, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        PuzzleApp(
          engine: PuzzleEngine(),
          initialState: finished(record: false),
          store: store,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('NEW PERSONAL BEST'), findsNothing);
      await tester.ensureVisible(find.text('Share score'));
      await tester.tap(find.text('Share score'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy score'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Score copied'), findsOneWidget);
      expect(
        (await Clipboard.getData(Clipboard.kTextPlain))?.text,
        scoreShareText(finished(record: false)),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
