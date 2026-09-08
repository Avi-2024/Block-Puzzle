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
    final double shortestSide = math.min(size.width, size.height);
    final Paint glowPaint = Paint()..style = PaintingStyle.fill;

    void drawGlow({
      required Offset center,
      required double radius,
      required Color color,
      double intensity = 1,
    }) {
      glowPaint.shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: .24 * intensity),
          color.withValues(alpha: .075 * intensity),
          color.withValues(alpha: 0),
        ],
        stops: const <double>[0, .44, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, glowPaint);
    }

    drawGlow(
      center: Offset(size.width * .13, size.height * .14),
      radius: shortestSide * .46,
      color: AppTheme.accent,
    );
    drawGlow(
      center: Offset(size.width * .88, size.height * .27),
      radius: shortestSide * .38,
      color: AppTheme.primary,
      intensity: .9,
    );
    drawGlow(
      center: Offset(size.width * .50, size.height * .90),
      radius: shortestSide * .36,
      color: AppTheme.success,
      intensity: .72,
    );

    final Paint sweepPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0x00FFFFFF),
          Color(0x16FFFFFF),
          Color(0x00FFFFFF),
        ],
        stops: <double>[0, .48, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sweepPaint);

    final Paint particlePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 42; i++) {
      final double seed = i * 37.0;
      final double x = (math.sin(seed) * .5 + .5) * size.width;
      final double y = (math.cos(seed * 1.37) * .5 + .5) * size.height;
      final double radius = .85 + (i % 4) * .34;
      particlePaint.color = Colors.white.withValues(
        alpha: i.isEven ? .082 : .045,
      );
      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }

    final Paint edgeLightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0x18FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * .20));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * .20), edgeLightPaint);

    final Paint vignettePaint = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[
          Colors.transparent,
          Color(0x73030A22),
        ],
        stops: <double>[.55, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignettePaint);
  }

  @override
  bool shouldRepaint(covariant _GameAtmospherePainter oldDelegate) => false;
}
