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
            final double enter = (phase * (cleared ? 5 : 7)).clamp(0.0, 1.0);
            final double fade = reducedMotion ? 1 :
                (math.min(1.0, phase * 11) *
                ((1 - phase) / .17).clamp(0.0, 1.0));
            final double comboIn = ((phase - .22) * 7).clamp(0.0, 1.0);
            final double praiseIn = ((phase - .38) * 7).clamp(0.0, 1.0);

            return Opacity(
              opacity: fade,
              child: Transform.translate(
                offset: Offset(0, reducedMotion ? 0 : 10 - 17 * phase),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (celebration)
                      Opacity(
                        opacity: praiseIn,
                        child: Transform.scale(
                          scale: .82 + .18 * Curves.easeOutBack.transform(praiseIn),
                          child: const Text(
                            'AWESOME!',
                            style: TextStyle(
                              color: AppTheme.rewardCoral,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              shadows: <Shadow>[
                                Shadow(color: Color(0xEE09152F), blurRadius: 4,
                                    offset: Offset(0, 3)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Transform.scale(
                      scale: .72 + .28 * Curves.easeOutBack.transform(enter),
                      child: Text(
                        '+$points',
                        style: TextStyle(
                          color: cleared ? Colors.white : AppTheme.rewardCyan,
                          fontSize: cleared ? 51 : 28,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          letterSpacing: -1.6,
                          shadows: <Shadow>[
                            Shadow(color: accent, blurRadius: cleared ? 7 : 4),
                            const Shadow(color: Color(0xFF07142D), blurRadius: 4,
                                offset: Offset(0, 4)),
                          ],
                        ),
                      ),
                    if (combo > 1)
                      Opacity(
                        opacity: comboIn,
                        child: Transform.scale(
                          scale: .82 + .18 * Curves.easeOutBack.transform(comboIn),
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
            );
          },
        ),
      ),
    );
  }
}
