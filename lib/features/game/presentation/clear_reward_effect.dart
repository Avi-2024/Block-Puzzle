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
    this.placementCenter,
    super.key,
  });

  final int points;
  final int lines;
  final int combo;
  final Set<int> rows;
  final Set<int> cols;
  /// Normalized board position used for moves that do not clear a line.
  final Offset? placementCenter;

  @override
  Widget build(BuildContext context) {
    final double x = cols.isEmpty ? (placementCenter?.dx ?? .5) :
        (cols.reduce((a, b) => a + b) / cols.length + .5) / GameEngine.size;
    final double y = rows.isEmpty ? (placementCenter?.dy ?? .5) :
        (rows.reduce((a, b) => a + b) / rows.length + .5) / GameEngine.size;
    // Keep the badge inside the board even for clears along its outer edges.
    final Alignment anchor = Alignment(
      (x.clamp(.25, .75) - .5) * 2,
      (y.clamp(.25, .75) - .5) * 2,
    );
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    final bool cleared = lines > 0;
    final Color accent = !cleared ? AppTheme.rewardCyan :
        combo > 1 ? AppTheme.rewardViolet :
        lines > 1 ? AppTheme.rewardCoral : AppTheme.rewardGold;
    final String caption = combo > 1 ? 'COMBO ×$combo' :
        lines > 1 ? '$lines LINES CLEARED' : cleared ? 'LINE CLEARED' : '';

    return IgnorePointer(
      child: Align(
        alignment: anchor,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: reducedMotion ? 0 : cleared ? 650 : 510),
          builder: (context, value, child) {
            final double opacity = reducedMotion ? 1 :
                math.min(1, value * 9) * ((1 - value) / .23).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, reducedMotion ? 0 : 12 - (cleared ? 32 : 24) * value),
                child: Transform.scale(
                  scale: reducedMotion ? 1 : .76 + .24 * Curves.easeOutBack.transform(
                    (value * 3).clamp(0.0, 1.0),
                  ),
                  child: cleared && !reducedMotion
                      ? CustomPaint(
                          foregroundPainter: _RewardSparks(value, accent),
                          child: child,
                        ) : child,
                ),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: cleared ? 17 : 12, vertical: cleared ? 9 : 5,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: <Color>[
                Color.lerp(AppTheme.gameBoard, accent, .33)!,
                AppTheme.gameBoard.withValues(alpha: .96),
              ]),
              borderRadius: BorderRadius.circular(cleared ? 15 : 12),
              border: Border.all(color: accent.withValues(alpha: .85)),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x59030A20), blurRadius: 14, offset: Offset(0, 5)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text('+$points', style: TextStyle(
                color: accent, fontSize: cleared ? 31 : 21,
                fontWeight: FontWeight.w900, height: 1, letterSpacing: -.8,
                shadows: <Shadow>[
                  Shadow(color: accent.withValues(alpha: .55), blurRadius: 12),
                ],
              )),
              if (cleared) ...<Widget>[
                const SizedBox(height: 4),
                Text(caption, style: const TextStyle(
                  color: AppTheme.gameText, fontSize: 10,
                  fontWeight: FontWeight.w900, letterSpacing: 1.1,
                )),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Six small, deterministic rays for clears; no assets or per-frame timers.
class _RewardSparks extends CustomPainter {
  const _RewardSparks(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double intensity = ((1 - progress) / .7).clamp(0.0, 1.0);
    if (intensity == 0) return;
    final Offset center = size.center(Offset.zero);
    final Paint spark = Paint()
      ..color = color.withValues(alpha: intensity * .85)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      final double angle = i * math.pi / 3;
      final Offset direction = Offset(math.cos(angle), math.sin(angle));
      final double distance = size.width * (.53 + progress * .17);
      canvas.drawLine(center + direction * distance,
          center + direction * (distance + 6 * intensity), spark);
    }
  }

  @override
  bool shouldRepaint(covariant _RewardSparks oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
