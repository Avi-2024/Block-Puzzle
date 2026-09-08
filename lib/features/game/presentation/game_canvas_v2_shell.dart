import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A paint-only ambience layer for the V2 gameplay canvas.
///
/// This is intentionally outside the game engine and controller. It adds a
/// studio-style light field without changing drag math, score rules, ads,
/// persistence, or daily-challenge behavior. The painter is static and wrapped
/// in a repaint boundary, so it does not add per-frame work during gameplay.
class GameCanvasV2Shell extends StatelessWidget {
  const GameCanvasV2Shell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _GameAtmospherePainter()),
            ),
          ),
        ),
      ],
    );
  }
}

class _GameAtmospherePainter extends CustomPainter {
  const _GameAtmospherePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint glowPaint = Paint()..style = PaintingStyle.fill;

    void drawGlow({
      required Offset center,
      required double radius,
      required Color color,
    }) {
      glowPaint.shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: .28),
          color.withValues(alpha: .08),
          color.withValues(alpha: 0),
        ],
        stops: const <double>[0, .45, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, glowPaint);
    }

    drawGlow(
      center: Offset(size.width * .18, size.height * .16),
      radius: math.min(size.width, size.height) * .42,
      color: AppTheme.accent,
    );
    drawGlow(
      center: Offset(size.width * .86, size.height * .28),
      radius: math.min(size.width, size.height) * .34,
      color: AppTheme.primary,
    );
    drawGlow(
      center: Offset(size.width * .52, size.height * .88),
      radius: math.min(size.width, size.height) * .32,
      color: AppTheme.success,
    );

    final Paint particlePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 34; i++) {
      final double seed = i * 37.0;
      final double x = (math.sin(seed) * .5 + .5) * size.width;
      final double y = (math.cos(seed * 1.37) * .5 + .5) * size.height;
      final double radius = 1.0 + (i % 3) * .45;
      particlePaint.color = Colors.white.withValues(alpha: i.isEven ? .10 : .055);
      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }

    final Paint vignettePaint = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[
          Colors.transparent,
          Color(0x66030A22),
        ],
        stops: <double>[.56, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant _GameAtmospherePainter oldDelegate) => false;
}
