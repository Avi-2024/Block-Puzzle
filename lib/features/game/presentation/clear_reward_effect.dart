import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A brief, non-interactive reward at the board center. Score, combo, and
/// praise arrive in sequence; no part of the background animates.
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
  // Kept for callers that also draw the line-clear effect. The reward itself
  // always appears in one predictable position, including edge placements.
  final Set<int> rows;
  final Set<int> cols;
  final Offset? placementCenter;

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    final bool cleared = lines > 0;
    final bool celebration = combo > 1 || lines > 1;
    final Color accent = cleared ? AppTheme.rewardGold : AppTheme.rewardCyan;

    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: reducedMotion ? 0 : cleared ? 860 : 460),
          builder: (BuildContext context, double value, Widget? child) {
            final double phase = reducedMotion ? .56 : value;
            final double fade = reducedMotion ? 1 :
                (math.min(1.0, phase * 11) *
                ((1 - phase) / .17).clamp(0.0, 1.0));
            final double comboIn = ((phase - .22) * 7).clamp(0.0, 1.0);
            final double praiseIn = ((phase - .38) * 7).clamp(0.0, 1.0);
            final double rise = ((phase - .44) / .56).clamp(0.0, 1.0);

            return Opacity(
              opacity: fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    if (celebration)
                      Opacity(
                        opacity: praiseIn,
                        child: Transform.scale(
                          scale: .68 + .32 * Curves.easeOutBack.transform(praiseIn),
                          child: const Text(
                            'AWESOME!',
                            style: TextStyle(
                              color: AppTheme.rewardCoral,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              shadows: <Shadow>[
                                Shadow(color: Color(0xFF07142D), offset: Offset(-2, -2)),
                                Shadow(color: Color(0xFF07142D), offset: Offset(2, 2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Transform.translate(
                      offset: Offset(0, reducedMotion ? 0 :
                          18 * (1 - (phase * 7).clamp(0.0, 1.0)) -
                          26 * Curves.easeIn.transform(rise)),
                      child: Transform.scale(
                        scale: reducedMotion ? 1 : _numberScale(phase),
                        child: CustomPaint(
                          foregroundPainter: _RewardTicks(
                            phase: phase, color: accent,
                          ),
                          child: Text(
                            '+$points',
                            style: TextStyle(
                              color: cleared ? Colors.white : AppTheme.rewardCyan,
                              fontSize: cleared ? 54 : 32,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: -1.6,
                              // Crisp ink edges stay legible even over yellow
                              // blocks. Movement and scale provide the reward;
                              // the number does not rely on a blurry halo.
                              shadows: const <Shadow>[
                                Shadow(color: Color(0xFF07142D), offset: Offset(-2, -2)),
                                Shadow(color: Color(0xFF07142D), offset: Offset(2, -2)),
                                Shadow(color: Color(0xFF07142D), offset: Offset(-2, 2)),
                                Shadow(color: Color(0xFF07142D), offset: Offset(2, 2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (combo > 1)
                      Opacity(
                        opacity: comboIn,
                        child: Transform.scale(
                          scale: .66 + .34 * Curves.easeOutBack.transform(comboIn),
                          child: Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.gameBoard.withValues(alpha: .94),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AppTheme.rewardGold),
                            ),
                            child: Text('COMBO +$combo',
                              style: const TextStyle(
                                color: AppTheme.rewardGold,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .6,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

double _numberScale(double phase) {
  if (phase < .15) {
    return .58 + .64 * Curves.easeOutCubic.transform(phase / .15);
  }
  if (phase < .27) {
    return 1.22 - .29 * Curves.easeInOut.transform((phase - .15) / .12);
  }
  if (phase < .41) {
    return .93 + .07 * Curves.easeOutCubic.transform((phase - .27) / .14);
  }
  return 1 - .10 * ((phase - .80) / .20).clamp(0.0, 1.0);
}

/// Short sharp ticks accompany the number's arrival, with no full-screen glow.
class _RewardTicks extends CustomPainter {
  const _RewardTicks({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double intensity = ((phase - .10) / .08).clamp(0.0, 1.0) *
        ((.42 - phase) / .18).clamp(0.0, 1.0);
    if (intensity <= 0) return;
    final Paint paint = Paint()
      ..color = color.withValues(alpha: intensity * .85)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final int side in <int>[-1, 1]) {
      final double x = side < 0 ? -6 : size.width + 6;
      canvas.drawLine(Offset(x, size.height * .22),
          Offset(x + side * 8, size.height * .13), paint);
      canvas.drawLine(Offset(x, size.height * .75),
          Offset(x + side * 9, size.height * .84), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RewardTicks oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.color != color;
}
