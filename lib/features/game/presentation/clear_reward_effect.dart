import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/game_engine.dart';

/// Short, non-interactive payoff anchored near the lines that earned the points.
/// Recreating this widget for a new clear starts a fresh animation immediately.
class ClearRewardEffect extends StatelessWidget {
  const ClearRewardEffect({
    required this.points,
    required this.lines,
    required this.combo,
    required this.rows,
    required this.cols,
    super.key,
  });

  final int points;
  final int lines;
  final int combo;
  final Set<int> rows;
  final Set<int> cols;

  @override
  Widget build(BuildContext context) {
    final double x = cols.isEmpty ? .5 :
        (cols.reduce((a, b) => a + b) / cols.length + .5) / GameEngine.size;
    final double y = rows.isEmpty ? .5 :
        (rows.reduce((a, b) => a + b) / rows.length + .5) / GameEngine.size;
    // Keep the badge inside the board even for clears along its outer edges.
    final Alignment anchor = Alignment(
      (x.clamp(.25, .75) - .5) * 2,
      (y.clamp(.25, .75) - .5) * 2,
    );
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    final String caption = combo > 1 ? 'COMBO ×$combo' :
        lines > 1 ? '$lines LINES CLEARED' : 'LINE CLEARED';

    return IgnorePointer(
      child: Align(
        alignment: anchor,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: reducedMotion ? 0 : 650),
          builder: (context, value, child) {
            final double opacity = reducedMotion ? 1 :
                math.min(1, value * 7) * ((1 - value) / .26).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, reducedMotion ? 0 : 12 - 30 * value),
                child: Transform.scale(
                  scale: reducedMotion ? 1 : .86 + .14 * Curves.easeOutBack.transform(
                    (value * 3).clamp(0.0, 1.0),
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.gameBoard.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.rewardGold.withValues(alpha: .55)),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x59030A20), blurRadius: 14, offset: Offset(0, 5)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text('+$points', style: const TextStyle(
                color: AppTheme.rewardGold, fontSize: 29, fontWeight: FontWeight.w900,
                height: 1, letterSpacing: -.8,
              )),
              const SizedBox(height: 3),
              Text(caption, style: const TextStyle(
                color: AppTheme.gameText, fontSize: 10, fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
