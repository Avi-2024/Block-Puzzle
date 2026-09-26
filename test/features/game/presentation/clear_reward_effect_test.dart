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
    expect(find.text('AWESOME!'), findsNothing);
    expect(find.byType(Center), findsWidgets);
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
    expect(find.text('COMBO +3'), findsOneWidget);
    expect(tester.getCenter(find.text('+420')).dx,
        closeTo(tester.getCenter(find.byType(ClearRewardEffect)).dx, 1));
    expect(tester.widget<Opacity>(find.ancestor(
      of: find.text('COMBO +3'), matching: find.byType(Opacity),
    ).first).opacity, 0);
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.text('AWESOME!'), findsOneWidget);
    expect(tester.widget<Opacity>(find.ancestor(
      of: find.text('AWESOME!'), matching: find.byType(Opacity),
    ).first).opacity, greaterThan(0));
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
    final Text number = tester.widget<Text>(find.text('+15'));
    expect(number.style!.color, AppTheme.rewardCyan);
    expect(number.style!.shadows, isNotEmpty);
    expect(number.style!.shadows!.every((shadow) => shadow.blurRadius == 0), isTrue);
    expect(find.text('LINE CLEARED'), findsNothing);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('first new best takes priority over clear praise', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.square(
      dimension: 320,
      child: ClearRewardEffect(
        points: 210, lines: 2, combo: 2, newBest: true,
        rows: <int>{0}, cols: <int>{1},
      ),
    )));
    await tester.pump(const Duration(milliseconds: 480));
    expect(find.text('NEW BEST!'), findsOneWidget);
    expect(find.text('AWESOME!'), findsNothing);
    expect(find.text('+210'), findsOneWidget);
    expect(find.text('COMBO +2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
