import 'package:blockiva/features/game/presentation/clear_reward_effect.dart';
import 'package:blockiva/core/theme/app_theme.dart';
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

  testWidgets('ordinary placement shows a compact cyan points reward', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.square(
      dimension: 320,
      child: ClearRewardEffect(
        points: 15, lines: 0, combo: 0,
        rows: <int>{}, cols: <int>{}, placementCenter: Offset(.25, .75),
      ),
    )));
    await tester.pump(const Duration(milliseconds: 140));
    expect(find.text('+15'), findsOneWidget);
    expect(tester.widget<Text>(find.text('+15')).style!.color, AppTheme.rewardCyan);
    expect(find.text('LINE CLEARED'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
