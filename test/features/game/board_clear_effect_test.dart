import 'package:blockiva/features/game/presentation/board_clear_effect.dart';
import 'package:flutter/material.dart';
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
}
