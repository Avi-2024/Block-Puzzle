import 'package:blockiva/features/game/presentation/blockiva_approved_gameplay_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('approved gameplay shell paints behind and above the game child',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BlockivaApprovedGameplayShell(
            child: SizedBox.expand(child: ColoredBox(color: Colors.transparent)),
          ),
        ),
      ),
    );

    expect(find.byType(BlockivaApprovedGameplayShell), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
