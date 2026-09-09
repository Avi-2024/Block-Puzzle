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
    _drawBoardDepthPlate(canvas, size, shortestSide);
    _drawBoardTargetingGuides(canvas, size, shortestSide);
    _drawBoardLaneEnergy(canvas, size, shortestSide);
    _drawMobileChromeCues(canvas, size);
    _drawReferenceAnchors(canvas, size);
    _drawHudScoreAccents(canvas, size);
    _drawTrayPieceWells(canvas, size);
    _drawPieceColorEchoes(canvas, size);

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

  void _drawBoardDepthPlate(Canvas canvas, Size size, double shortestSide) {
    final double plateSize = math.min(size.width - 24, shortestSide * .94);
    final Rect plateRect = Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .50),
      width: plateSize,
      height: plateSize,
    );
    final RRect outerPlate = RRect.fromRectAndRadius(
      plateRect.inflate(18),
      const Radius.circular(34),
    );
    final Paint plateShadowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.black.withValues(alpha: .18),
          Colors.black.withValues(alpha: .075),
          Colors.transparent,
        ],
        stops: const <double>[0, .58, 1],
      ).createShader(plateRect.inflate(68));
    canvas.drawRRect(outerPlate, plateShadowPaint);

    final Paint plateSheenPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0x0EFFFFFF),
          Color(0x00000000),
          Color(0x12000000),
        ],
        stops: <double>[0, .48, 1],
      ).createShader(outerPlate.outerRect);
    canvas.drawRRect(outerPlate, plateSheenPaint);
  }

  void _drawBoardTargetingGuides(Canvas canvas, Size size, double shortestSide) {
    final double boardFocusSize = math.min(size.width - 34, shortestSide * .90);
    final Rect boardRect = Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .50),
      width: boardFocusSize,
      height: boardFocusSize,
    );
    final RRect guideRect = RRect.fromRectAndRadius(
      boardRect.inflate(17),
      const Radius.circular(31),
    );
    final Paint guideGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..color = AppTheme.primary.withValues(alpha: .020)
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(guideRect, guideGlowPaint);

    final Paint tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .075);
    const double tickLength = 23;
    final List<Offset> corners = <Offset>[
      boardRect.topLeft,
      boardRect.topRight,
      boardRect.bottomRight,
      boardRect.bottomLeft,
    ];

    for (final Offset corner in corners) {
      final double horizontalDirection = corner.dx < size.width / 2 ? 1 : -1;
      final double verticalDirection = corner.dy < size.height / 2 ? 1 : -1;
      canvas
        ..drawLine(
          corner,
          corner.translate(tickLength * horizontalDirection, 0),
          tickPaint,
        )
        ..drawLine(
          corner,
          corner.translate(0, tickLength * verticalDirection),
          tickPaint,
        );
    }
  }

  void _drawBoardLaneEnergy(Canvas canvas, Size size, double shortestSide) {
    final double boardFocusSize = math.min(size.width - 34, shortestSide * .90);
    final Rect boardRect = Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .50),
      width: boardFocusSize,
      height: boardFocusSize,
    );
    final Paint horizontalLanePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x00000000),
          Color(0x1438F2A0),
          Color(0x10FFFFFF),
          Color(0x00000000),
        ],
        stops: <double>[0, .28, .55, 1],
      ).createShader(boardRect.inflate(38));
    final Paint verticalLanePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0x00000000),
          Color(0x1056A3FF),
          Color(0x10FFFFFF),
          Color(0x00000000),
        ],
        stops: <double>[0, .32, .62, 1],
      ).createShader(boardRect.inflate(38));

    for (var i = 1; i <= 3; i++) {
      final double ratio = i / 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * .50, boardRect.top + boardRect.height * ratio),
            width: boardRect.width + 58,
            height: 4.8,
          ),
          const Radius.circular(99),
        ),
        horizontalLanePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(boardRect.left + boardRect.width * ratio, size.height * .50),
            width: 4.8,
            height: boardRect.height + 58,
          ),
          const Radius.circular(99),
        ),
        verticalLanePaint,
      );
    }
  }

  void _drawMobileChromeCues(Canvas canvas, Size size) {
    final Paint topChromePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0x22000000),
          Color(0x00000000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 116));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 116), topChromePaint);

    final Rect trayRail = Rect.fromLTWH(
      22,
      size.height * .79,
      math.max(0, size.width - 44),
      86,
    );
    final Paint trayRailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.white.withValues(alpha: .075),
          Colors.white.withValues(alpha: .028),
          Colors.black.withValues(alpha: .12),
        ],
        stops: const <double>[0, .52, 1],
      ).createShader(trayRail);
    canvas.drawRRect(
      RRect.fromRectAndRadius(trayRail, const Radius.circular(28)),
      trayRailPaint,
    );

    final Paint railPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0x00FFFFFF),
          Color(0x13FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(Offset.zero & size);
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, 1.2, size.height), railPaint)
      ..drawRect(
        Rect.fromLTWH(size.width - 1.2, 0, 1.2, size.height),
        railPaint,
      );
  }

  void _drawReferenceAnchors(Canvas canvas, Size size) {
    final double anchorY = size.height * .215;
    final double gap = size.width * .28;
    final double startX = (size.width - gap * 2) / 2;
    final Paint anchorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .075);

    for (var i = 0; i < 3; i++) {
      final Offset center = Offset(startX + gap * i, anchorY);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 74, height: 46),
          const Radius.circular(14),
        ),
        anchorPaint,
      );
    }
  }

  void _drawHudScoreAccents(Canvas canvas, Size size) {
    final double hudY = math.min(54, size.height * .095);
    final Offset leftHudCenter = Offset(34, hudY);
    final Offset rightHudCenter = Offset(size.width - 34, hudY);
    final Paint hudHaloPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: .090),
          AppTheme.primary.withValues(alpha: .052),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: leftHudCenter, radius: 46));
    canvas.drawCircle(leftHudCenter, 46, hudHaloPaint);

    hudHaloPaint.shader = RadialGradient(
      colors: <Color>[
        Colors.white.withValues(alpha: .090),
        AppTheme.accent.withValues(alpha: .050),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: rightHudCenter, radius: 46));
    canvas.drawCircle(rightHudCenter, 46, hudHaloPaint);

    final Rect scorePlate = Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .205),
      width: math.min(188, size.width * .54),
      height: 76,
    );
    final Paint scoreGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: .070),
          AppTheme.warning.withValues(alpha: .038),
          Colors.transparent,
        ],
        stops: const <double>[0, .48, 1],
      ).createShader(scorePlate.inflate(42));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        scorePlate.inflate(18),
        const Radius.circular(34),
      ),
      scoreGlowPaint,
    );

    final Paint scoreStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .058);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scorePlate, const Radius.circular(24)),
      scoreStrokePaint,
    );
  }

  void _drawTrayPieceWells(Canvas canvas, Size size) {
    final double slotY = size.height * .855;
    final double gap = size.width * .285;
    final double startX = (size.width - gap * 2) / 2;
    final Paint wellFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.white.withValues(alpha: .052),
          Colors.black.withValues(alpha: .105),
        ],
      ).createShader(Rect.fromLTWH(0, slotY - 42, size.width, 84));
    final Paint wellStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .080);

    for (var i = 0; i < 3; i++) {
      final Rect slotRect = Rect.fromCenter(
        center: Offset(startX + gap * i, slotY),
        width: 88,
        height: 76,
      );
      final RRect slot = RRect.fromRectAndRadius(
        slotRect,
        const Radius.circular(24),
      );
      canvas
        ..drawRRect(slot, wellFillPaint)
        ..drawRRect(slot, wellStrokePaint);
    }
  }

  void _drawPieceColorEchoes(Canvas canvas, Size size) {
    final double baseY = size.height * .925;
    final double step = size.width / (AppTheme.piecePalette.length + 1);
    final Paint echoPaint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < AppTheme.piecePalette.length; i++) {
      final Color color = AppTheme.piecePalette[i];
      final Offset center = Offset(step * (i + 1), baseY - (i.isEven ? 4 : 0));
      echoPaint.shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: .115),
          color.withValues(alpha: .032),
          color.withValues(alpha: 0),
        ],
        stops: const <double>[0, .50, 1],
      ).createShader(Rect.fromCircle(center: center, radius: 28));
      canvas.drawCircle(center, 28, echoPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GameAtmospherePainter oldDelegate) => false;
}
