import 'package:blockiva/features/game/presentation/clear_reward_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clear reward shows earned points and yields to the next drag', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: SizedBox.square(dimension: 320, child: Stack(
      children: <Widget>[
        Positioned.fill(child: GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: () => taps++,
        )),
        const Positioned.fill(child: ClearRewardEffect(
          points: 115, lines: 1, combo: 1, rows: <int>{5}, cols: <int>{},
        )),
      ],
    ))));
    await tester.pump(const Duration(milliseconds: 170));
    expect(find.text('+115'), findsOneWidget);
    expect(find.text('LINE CLEARED'), findsOneWidget);
    await tester.tapAt(const Offset(160, 160));
    expect(taps, 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.square(
      dimension: 320,
      child: ClearRewardEffect(
        points: 420, lines: 2, combo: 3, rows: <int>{}, cols: <int>{1, 2},
      ),
    )));
    await tester.pump(const Duration(milliseconds: 170));
    expect(find.text('+420'), findsOneWidget);
    expect(find.text('COMBO ×3'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
