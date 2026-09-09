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

    _drawScoreAndTrayBands(canvas, size);
    _drawPlayfieldFocus(canvas, size, shortestSide);

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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * .20),
      edgeLightPaint,
    );

    _drawGameplayChrome(canvas, size);

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

  void _drawScoreAndTrayBands(Canvas canvas, Size size) {
    final Paint scoreBandPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x00000000),
          Color(0x16FFFFFF),
          Color(0x00000000),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * .13, size.width, 74));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .13, size.width, 74),
      scoreBandPaint,
    );

    final Paint trayBandPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x00000000),
          Color(0x1238F2A0),
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromLTWH(0, size.height * .78, size.width, 118));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .78, size.width, 118),
      trayBandPaint,
    );
  }

  void _drawPlayfieldFocus(Canvas canvas, Size size, double shortestSide) {
    final double boardFocusSize = math.min(size.width - 28, shortestSide * .92);
    final Rect focusRect = Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .50),
      width: boardFocusSize,
      height: boardFocusSize,
    );

    final Paint haloPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: .105),
          AppTheme.primary.withValues(alpha: .065),
          Colors.transparent,
        ],
        stops: const <double>[0, .42, 1],
      ).createShader(focusRect.inflate(84));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        focusRect.inflate(30),
        const Radius.circular(36),
      ),
      haloPaint,
    );

    final Paint boardEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .055);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        focusRect.inflate(11),
        const Radius.circular(28),
      ),
      boardEdgePaint,
    );
  }

  void _drawGameplayChrome(Canvas canvas, Size size) {
    final RRect topChrome = RRect.fromRectAndRadius(
      Rect.fromLTWH(18, 22, size.width - 36, 52),
      const Radius.circular(28),
    );
    final Paint topChromePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0x10FFFFFF),
          Color(0x05000000),
        ],
      ).createShader(topChrome.outerRect);
    canvas.drawRRect(topChrome, topChromePaint);

    final Paint chromeStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x00FFFFFF),
          Color(0x22FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(topChrome.outerRect);
    canvas.drawRRect(topChrome, chromeStrokePaint);

    final Rect bottomRailRect = Rect.fromLTWH(22, size.height - 150, size.width - 44, 92);
    final Paint bottomRailPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0x00000000),
          Color(0x1438F2A0),
          Color(0x09000000),
        ],
        stops: <double>[0, .62, 1],
      ).createShader(bottomRailRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bottomRailRect, const Radius.circular(34)),
      bottomRailPaint,
    );

    final Paint sideRailPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x00FFFFFF),
          Color(0x10FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Rect.fromLTWH(0, 0, 1.2, size.height), sideRailPaint);
    canvas.drawRect(
      Rect.fromLTWH(size.width - 1.2, 0, 1.2, size.height),
      sideRailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GameAtmospherePainter oldDelegate) => false;
}
