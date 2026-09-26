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
    this.newBest = false,
    this.placementCenter,
    super.key,
  });

  final int points;
  final int lines;
  final int combo;
  final bool newBest;
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
    final bool spectacle = cleared || newBest;
    final Color accent = cleared ? AppTheme.rewardGold : AppTheme.rewardCyan;

    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: reducedMotion ? 0 : spectacle ? 860 : 460),
          builder: (BuildContext context, double value, Widget? child) {
            final double phase = reducedMotion ? .56 : value;
            final double fade = reducedMotion ? 1 :
                (math.min(1.0, phase * 11) *
                ((1 - phase) / .17).clamp(0.0, 1.0));
            // Reveal the headline while the clear is still visible. Waiting
            // until the end of this short effect lets Android drop nearly all
            // of its visible frames on slower devices.
            final double comboIn = ((phase - .12) * 12).clamp(0.0, 1.0);
            final double praiseIn = ((phase - .09) * 12).clamp(0.0, 1.0);
            final double rise = ((phase - .44) / .56).clamp(0.0, 1.0);

            return Opacity(
              opacity: fade,
              child: SizedBox(
                width: math.min(MediaQuery.sizeOf(context).width * .66, 260),
                child: CustomPaint(
                painter: spectacle && !reducedMotion ? _RewardBackdrop(
                  phase: phase,
                  primary: newBest ? AppTheme.rewardCoral :
                      combo > 1 ? AppTheme.rewardCyan : const Color(0xFF71DF82),
                  secondary: AppTheme.rewardGold,
                ) : null,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                    if (celebration || newBest)
                      Opacity(
                        opacity: praiseIn,
                        child: Transform.scale(
                          scale: .68 + .32 * Curves.easeOutBack.transform(praiseIn),
                          child: Text(
                            newBest ? 'NEW BEST!' : 'AWESOME!',
                            style: TextStyle(
                              color: newBest ? AppTheme.rewardGold :
                                  AppTheme.rewardCoral,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              shadows: const <Shadow>[
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
                ),
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

/// A small moving colour field behind the reward only. It paints no blur and
/// leaves the surrounding board and the screen background unchanged.
class _RewardBackdrop extends CustomPainter {
  const _RewardBackdrop({
    required this.phase,
    required this.primary,
    required this.secondary,
  });

  final double phase;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final double enter = ((phase - .07) * 9).clamp(0.0, 1.0);
    final double leave = ((1 - phase) * 5).clamp(0.0, 1.0);
    final double strength = enter * leave;
    if (strength <= 0) return;
    final Rect band = Rect.fromLTWH(0, size.height * .22,
        size.width, size.height * .60);
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, const Radius.circular(18)),
      Paint()..shader = LinearGradient(
        colors: <Color>[
          primary.withValues(alpha: 0),
          primary.withValues(alpha: .38 * strength),
          secondary.withValues(alpha: .31 * strength),
          secondary.withValues(alpha: 0),
        ],
      ).createShader(band),
    );

    // Deterministic positions keep repainting cheap and prevent visual noise.
    for (int index = 0; index < 9; index++) {
      final double travel = (phase * 92 + index * 35) % (size.width + 50);
      final double x = travel - 25;
      final double y = size.height * (.27 + index * .055);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 38 + (index % 2) * 16, 4),
          const Radius.circular(2),
        ),
        Paint()..color = (index.isEven ? primary : secondary)
            .withValues(alpha: .58 * strength),
      );
    }
    for (int index = 0; index < 18; index++) {
      final double x = (index * 47 + phase * (index.isEven ? 42 : -34)) %
          (size.width + 20) - 10;
      final double y = size.height * (.25 + ((index * 7) % 11) * .05);
      canvas.drawCircle(Offset(x, y), index % 3 == 0 ? 2.2 : 1.3,
          Paint()..color = (index.isEven ? secondary : primary)
              .withValues(alpha: .83 * strength));
    }
  }

  @override
  bool shouldRepaint(covariant _RewardBackdrop oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary;
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
