import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Original interlocking block mark, shared by launch and gameplay branding.
/// Painted rather than loaded so the first frame needs no asset decode.
class BlockivaMark extends StatelessWidget {
  const BlockivaMark({this.size = 72, super.key});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: const ExcludeSemantics(child: CustomPaint(painter: _MarkPainter())),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / 3;
    const cells = <(int, int, Color)>[
      (0, 0, AppTheme.rewardCyan),
      (0, 1, AppTheme.rewardCyan),
      (0, 2, AppTheme.rewardCyan),
      (1, 0, AppTheme.primary),
      (1, 1, AppTheme.primary),
      (1, 2, AppTheme.rewardGold),
      (2, 1, AppTheme.rewardGold),
      (2, 2, AppTheme.rewardGold),
    ];
    for (final (col, row, color) in cells) {
      final rect = Rect.fromLTWH(
        col * cell + cell * .06,
        row * cell + cell * .06,
        cell * .88,
        cell * .88,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * .16)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, Colors.white, .18)!, color],
          ).createShader(rect),
      );
      canvas.drawLine(
        rect.topLeft + Offset(cell * .15, cell * .13),
        rect.topRight + Offset(-cell * .15, cell * .13),
        Paint()
          ..color = Colors.white.withValues(alpha: .32)
          ..strokeWidth = cell * .05
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
