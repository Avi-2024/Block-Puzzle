import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A short Blockiva score milestone. Does not pause or capture board input.
class MilestoneCelebration extends StatelessWidget {
  const MilestoneCelebration({required this.score, super.key});

  final int score;

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
    final bool major = score % 1000 == 0;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: reducedMotion ? 0 : 800),
        builder: (context, progress, child) {
          final double opacity = reducedMotion ? 1 :
              math.min(1, progress * 8) * ((1 - progress) / .24).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: CustomPaint(
              painter: _MilestonePainter(progress, major),
              child: Center(child: Transform.scale(
                scale: reducedMotion ? 1 : .82 + .18 * Curves.easeOutBack.transform(
                  (progress * 3).clamp(0.0, 1.0)),
                child: child,
              )),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.gameBoard.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: major ? AppTheme.rewardGold :
                AppTheme.rewardCyan, width: 1.5),
            boxShadow: <BoxShadow>[
              BoxShadow(color: (major ? AppTheme.rewardGold : AppTheme.rewardCyan)
                  .withValues(alpha: .4), blurRadius: 22),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(major ? 'BLOCKIVA BURST' : 'NICE RUN',
              style: const TextStyle(color: AppTheme.gameText, fontSize: 17,
                fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 3),
            Text('$score POINTS', style: TextStyle(
              color: major ? AppTheme.rewardGold : AppTheme.rewardCyan,
              fontSize: 13, fontWeight: FontWeight.w800,
            )),
          ]),
        ),
      ),
    );
  }
}

class _MilestonePainter extends CustomPainter {
  const _MilestonePainter(this.progress, this.major);
  final double progress;
  final bool major;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final Color color = major ? AppTheme.rewardGold : AppTheme.rewardCyan;
    final double radius = size.shortestSide * (.18 + .20 * progress);
    final Paint glow = Paint()
      ..shader = RadialGradient(colors: <Color>[
        color.withValues(alpha: .24 * (1 - progress)),
        color.withValues(alpha: 0),
      ]).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * .5));
    canvas.drawCircle(center, size.shortestSide * .5, glow);
    final Paint tile = Paint()..color = color.withValues(
        alpha: ((1 - progress) / .65).clamp(0.0, 1.0));
    for (int i = 0; i < 8; i++) {
      final double angle = i * math.pi / 4;
      final Offset point = center + Offset(math.cos(angle) * radius,
          math.sin(angle) * radius);
      final double side = 5 * (1 - progress * .55);
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle);
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        const Radius.circular(1),
      ), tile);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MilestonePainter oldDelegate) =>
      progress != oldDelegate.progress || major != oldDelegate.major;
}
