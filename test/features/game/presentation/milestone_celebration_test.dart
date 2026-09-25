import 'package:blockiva/features/game/presentation/milestone_celebration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('milestone is readable and never blocks a board tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: SizedBox.square(
      dimension: 320,
      child: Stack(children: <Widget>[
        Positioned.fill(child: GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: () => taps++,
        )),
        const Positioned.fill(child: MilestoneCelebration(score: 1000)),
      ]),
    )));
    await tester.pump(const Duration(milliseconds: 140));
    expect(find.text('BLOCKIVA BURST'), findsOneWidget);
    expect(find.text('1000 POINTS'), findsOneWidget);
    await tester.tapAt(const Offset(160, 160));
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
