import 'dart:ui' as ui;

import 'package:blockiva/features/game/presentation/board_clear_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clear effect finishes and does not intercept the next move', (tester) async {
    int taps = 0;
    await tester.pumpWidget(MaterialApp(home: SizedBox.expand(child: Stack(
      children: <Widget>[
        Positioned.fill(child: GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: () => taps++,
        )),
        const Positioned.fill(child: BoardClearEffect(rows: <int>{2}, cols: <int>{4})),
      ],
    ))));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tapAt(const Offset(200, 200));
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('completed tile stays visible briefly before it clears', (tester) async {
    final capture = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: Center(child: RepaintBoundary(
      key: capture,
      child: const SizedBox.square(dimension: 320, child: BoardClearEffect(
        rows: <int>{2}, cols: <int>{}, tileColors: <int, int>{19: 5},
      )),
    ))));
    await tester.pump(const Duration(milliseconds: 60));
    final rgba = await tester.runAsync<List<int>>(() async {
      final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return bytes!.buffer.asUint8List();
    });
    final offset = ((2 * 40 + 20) * 320 + (3 * 40 + 20)) * 4;
    expect(rgba![offset], greaterThan(rgba[offset + 2]));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
