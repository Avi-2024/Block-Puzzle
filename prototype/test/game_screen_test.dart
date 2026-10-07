import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_prototype/game/puzzle.dart';
import 'package:puzzle_prototype/main.dart';

Future<void> capture(WidgetTester tester,GlobalKey key,String name) async {
  if(Platform.environment['PUZZLE_CAPTURE_UI']!='1')return;
  await tester.runAsync(() async {
    final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image=await boundary.toImage(pixelRatio:2);
    final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
    final directory=Directory('build/prototype-review')..createSync(recursive:true);
    File('${directory.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if(Platform.environment['PUZZLE_CAPTURE_UI']=='1') {
      final artifacts=File(Platform.resolvedExecutable).parent.parent.parent;
      final loader=FontLoader('Roboto');var found=false;
      for(final name in ['Roboto-Regular.ttf','Roboto-Bold.ttf']) {
        final font=File('${artifacts.path}/material_fonts/$name');
        if(await font.exists()){found=true;loader.addFont(font.readAsBytes().then(ByteData.sublistView));}
      }
      if(found)await loader.load();
    }
  });
  for(final size in [const Size(320,568),const Size(360,640),const Size(393,852),const Size(412,915)]) {
    testWidgets('gameplay and settings fit $size', (tester) async {
      tester.view.physicalSize=size;tester.view.devicePixelRatio=1;tester.view.padding=const FakeViewPadding(top:24,bottom:24);
      addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);addTearDown(tester.view.resetPadding);
      final key=GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key:key,child:PuzzleApp(engine:PuzzleEngine(random:Random(8)),initialState:reviewScene())));
      await tester.pumpAndSettle();expect(tester.takeException(),isNull);
      await capture(tester,key,'game-${size.width.toInt()}');
      await tester.tap(find.byTooltip('Settings'));await tester.pumpAndSettle();
      expect(find.text('Reduce motion'),findsOneWidget);expect(tester.takeException(),isNull);
      await tester.tap(find.text('Keep playing'));await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('real touch drag uses the displayed ghost and earns the clear', (tester) async {
    tester.view.physicalSize=const Size(393,852);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final key=GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key:key,child:PuzzleApp(engine:PuzzleEngine(random:Random(8)),initialState:reviewScene())));
    await tester.pumpAndSettle();
    final rect=tester.getRect(find.byKey(const ValueKey('puzzle-board'))),unit=rect.width*38/320,pad=rect.width*8/320;
    final start=tester.getCenter(find.byKey(const ValueKey('piece-slot-0')));
    final gesture=await tester.startGesture(start,kind:ui.PointerDeviceKind.touch);
    await gesture.moveBy(const Offset(0,-22));await tester.pump();
    await gesture.moveTo(rect.topLeft+Offset(pad+2*unit+3*unit/2,pad+2*unit+unit/2+54));await tester.pump();
    await capture(tester,key,'drag-shadow');await gesture.up();await tester.pump();await tester.pump(const Duration(milliseconds:280));
    expect(find.bySemanticsLabel('Score 1390'),findsOneWidget);expect(tester.takeException(),isNull);
    await capture(tester,key,'nice-clear');await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('piece-slot-1')));await tester.pump();
    await tester.tapAt(rect.topLeft+Offset(pad+6*unit+10,pad+3*unit+10));await tester.pump();await tester.pump(const Duration(milliseconds:300));
    expect(find.bySemanticsLabel('Score 1740'),findsOneWidget);await capture(tester,key,'combo-two');await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('piece-slot-2')));await tester.pump();
    await tester.tapAt(rect.topLeft+Offset(pad+2*unit+10,pad+5*unit+10));await tester.pump();await tester.pump(const Duration(milliseconds:300));
    expect(find.bySemanticsLabel('Score 2260'),findsOneWidget);await capture(tester,key,'amazing-three');
    await tester.pumpAndSettle();expect(tester.binding.hasScheduledFrame,isFalse);expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('background interruption cancels a drag without placing a piece', (tester) async {
    await tester.pumpWidget(PuzzleApp(engine:PuzzleEngine(),initialState:reviewScene()));await tester.pumpAndSettle();
    final gesture=await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('piece-slot-0'))));
    await gesture.moveBy(const Offset(0,-40));await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);await tester.pump();
    await gesture.up();tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Score 1280'),findsOneWidget);expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
