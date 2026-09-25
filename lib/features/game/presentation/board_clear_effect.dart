import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/game_engine.dart';

/// Short event-driven feedback, clipped to the real board geometry.
class BoardClearEffect extends StatelessWidget {
  const BoardClearEffect({required this.rows, required this.cols, super.key});
  final Set<int> rows;
  final Set<int> cols;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          builder: (BuildContext context, double progress, Widget? child) =>
              CustomPaint(painter: _ClearPainter(rows, cols, progress)),
        ),
      ),
    );
  }
}

class _ClearPainter extends CustomPainter {
  const _ClearPainter(this.rows, this.cols, this.progress);
  final Set<int> rows;
  final Set<int> cols;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.width / GameEngine.size;
    final double fade = math.pow(1 - progress, 1.6).toDouble();
    final Paint flash = Paint()
      ..color = AppTheme.rewardGold.withValues(alpha: fade * .76);
    final Paint spark = Paint();
    // The soft line sweep gives the eye a single readable clear event before
    // the small sparks dissipate. All drawing stays within one board layer.
    final Paint line = Paint()
      ..color = AppTheme.rewardGold.withValues(alpha: fade * .26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, cell * .07);
    for (final int row in rows) {
      final double y = (row + .5) * cell;
      canvas.drawLine(Offset(0, y), Offset(size.width * progress, y), line);
    }
    for (final int col in cols) {
      final double x = (col + .5) * cell;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * progress), line);
    }
    for (int row = 0; row < GameEngine.size; row++) {
      for (int col = 0; col < GameEngine.size; col++) {
        if (!rows.contains(row) && !cols.contains(col)) continue;
        final Offset center = Offset((col + .5) * cell, (row + .5) * cell);
        final double side = cell * (1 - progress * .78);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: side, height: side),
          const Radius.circular(3),
        ), flash);
        // Two deterministic sparks per cell; intersections draw only once.
        for (int i = 0; i < 2; i++) {
          final double angle = i * math.pi + (row + col) * .7;
          final double distance = cell * progress * (1 + i * .12);
          final Offset position = center + Offset(
            math.cos(angle) * distance,
            math.sin(angle) * distance + progress * progress * cell * .7,
          );
          spark.color = (i.isEven ? Colors.white : AppTheme.rewardGold)
              .withValues(alpha: fade);
          canvas.drawCircle(position, math.max(.5, cell * .045 * (1 - progress)), spark);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ClearPainter oldDelegate) =>
      progress != oldDelegate.progress || rows != oldDelegate.rows || cols != oldDelegate.cols;
}
