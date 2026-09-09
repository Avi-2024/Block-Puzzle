import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Paint-only shell for the approved Blockiva gameplay direction.
///
/// The approved reference is board-first, glossy, colorful, and relaxed. This
/// shell intentionally keeps gameplay, scoring, drag math, ads, persistence,
/// and controller state untouched while adding the new art direction as a safe
/// visual layer around the existing game screen.
class BlockivaApprovedGameplayShell extends StatelessWidget {
  const BlockivaApprovedGameplayShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _ApprovedBackgroundPainter()),
          ),
        ),
        child,
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _ApprovedGameplayOverlayPainter()),
            ),
          ),
        ),
      ],
    );
  }
}

class _ApprovedBackgroundPainter extends CustomPainter {
  const _ApprovedBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF1027B4),
            Color(0xFF2F1E78),
            Color(0xFF071134),
          ],
          stops: <double>[0, .48, 1],
        ).createShader(Offset.zero & size),
    );

    _drawSoftWorldDepth(canvas, size);
    _drawFloatingCubes(canvas, size);
    _drawStarField(canvas, size);
  }

  void _drawSoftWorldDepth(Canvas canvas, Size size) {
    final Paint glowPaint = Paint();
    void glow(Offset center, double radius, Color color, double alpha) {
      glowPaint.shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: alpha),
          color.withValues(alpha: alpha * .36),
          Colors.transparent,
        ],
        stops: const <double>[0, .52, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, glowPaint);
    }

    final double shortSide = math.min(size.width, size.height);
    glow(Offset(size.width * .50, size.height * .34), shortSide * .62,
        const Color(0xFF8C60FF), .26);
    glow(Offset(size.width * .12, size.height * .16), shortSide * .42,
        const Color(0xFF20D8FF), .20);
    glow(Offset(size.width * .92, size.height * .82), shortSide * .48,
        const Color(0xFFFF6CC8), .16);
    glow(Offset(size.width * .48, size.height * .86), shortSide * .40,
        const Color(0xFF38F2A0), .10);
  }

  void _drawFloatingCubes(Canvas canvas, Size size) {
    final Paint cubePaint = Paint()..style = PaintingStyle.fill;
    final Paint cubeStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var i = 0; i < 14; i++) {
      final double seed = i * 23.0;
      final double x = (math.sin(seed) * .5 + .5) * size.width;
      final double y = size.height * (.13 + ((math.cos(seed * .83) * .5 + .5) * .77));
      final double side = 10 + (i % 4) * 6;
      final RRect cube = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: side, height: side),
        Radius.circular(side * .28),
      );
      final Color color = AppTheme.piecePalette[i % AppTheme.piecePalette.length];
      cubePaint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Colors.white.withValues(alpha: .18),
          color.withValues(alpha: .16),
          color.withValues(alpha: .04),
        ],
      ).createShader(cube.outerRect);
      cubeStrokePaint.color = Colors.white.withValues(alpha: .10);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((i.isEven ? 1 : -1) * .14);
      canvas.translate(-x, -y);
      canvas.drawRRect(cube, cubePaint);
      canvas.drawRRect(cube, cubeStrokePaint);
      canvas.restore();
    }
  }

  void _drawStarField(Canvas canvas, Size size) {
    final Paint particlePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 58; i++) {
      final double seed = i * 41.0;
      final double x = (math.sin(seed) * .5 + .5) * size.width;
      final double y = (math.cos(seed * 1.31) * .5 + .5) * size.height;
      final double radius = .7 + (i % 5) * .24;
      particlePaint.color = Colors.white.withValues(alpha: i.isEven ? .12 : .052);
      canvas.drawCircle(Offset(x, y), radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ApprovedGameplayOverlayPainter extends CustomPainter {
  const _ApprovedGameplayOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double shortSide = math.min(size.width, size.height);
    _drawHeroScoreAura(canvas, size, shortSide);
    _drawBoardHeroFrame(canvas, size, shortSide);
    _drawClearEnergyPreview(canvas, size, shortSide);
    _drawTrayPedestal(canvas, size);
    _drawBottomCrystalGlow(canvas, size, shortSide);
    _drawEdgeVignette(canvas, size);
  }

  void _drawHeroScoreAura(Canvas canvas, Size size, double shortSide) {
    final Offset scoreCenter = Offset(size.width * .50, size.height * .19);
    final Rect scoreRect = Rect.fromCenter(
      center: scoreCenter,
      width: math.min(size.width * .58, 260),
      height: 86,
    );
    final RRect scoreBadge = RRect.fromRectAndRadius(
      scoreRect,
      const Radius.circular(30),
    );

    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: .12),
          AppTheme.primary.withValues(alpha: .11),
          Colors.transparent,
        ],
        stops: const <double>[0, .54, 1],
      ).createShader(scoreRect.inflate(shortSide * .20));
    canvas.drawRRect(scoreBadge.inflate(28), glowPaint);

    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0x55FFFFFF),
          Color(0x2256A3FF),
          Color(0x00FFFFFF),
        ],
      ).createShader(scoreRect.inflate(2));
    canvas.drawRRect(scoreBadge.inflate(2), rimPaint);

    final Paint crownGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppTheme.warning.withValues(alpha: .22),
          AppTheme.warning.withValues(alpha: .04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: scoreCenter.translate(0, -42),
        radius: 44,
      ));
    canvas.drawCircle(scoreCenter.translate(0, -42), 44, crownGlowPaint);
  }

  void _drawBoardHeroFrame(Canvas canvas, Size size, double shortSide) {
    final Rect boardRect = _boardRect(size, shortSide);
    final RRect outerBoard = RRect.fromRectAndRadius(
      boardRect.inflate(18),
      const Radius.circular(34),
    );

    final Paint depthPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.black.withValues(alpha: .28),
          Colors.black.withValues(alpha: .14),
          Colors.transparent,
        ],
        stops: const <double>[0, .58, 1],
      ).createShader(boardRect.inflate(88));
    canvas.drawRRect(outerBoard.inflate(14), depthPaint);

    final Paint haloPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          const Color(0xFF20D8FF).withValues(alpha: .20),
          AppTheme.primary.withValues(alpha: .14),
          const Color(0xFFFF6CC8).withValues(alpha: .12),
        ],
      ).createShader(outerBoard.outerRect);
    canvas.drawRRect(outerBoard, haloPaint);

    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0x88FFFFFF),
          Color(0xAA20D8FF),
          Color(0x664A5CFF),
          Color(0x55FF6CC8),
        ],
        stops: <double>[0, .30, .72, 1],
      ).createShader(outerBoard.outerRect);
    canvas.drawRRect(outerBoard, rimPaint);
  }

  void _drawClearEnergyPreview(Canvas canvas, Size size, double shortSide) {
    final Rect boardRect = _boardRect(size, shortSide);
    final double y = boardRect.top + boardRect.height * .57;
    final Rect beamRect = Rect.fromCenter(
      center: Offset(size.width * .50, y),
      width: boardRect.width + 66,
      height: 22,
    );
    final Paint beamPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x00000000),
          Color(0x3320D8FF),
          Color(0x66FFFFFF),
          Color(0x3320D8FF),
          Color(0x00000000),
        ],
        stops: <double>[0, .18, .50, .82, 1],
      ).createShader(beamRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(beamRect, const Radius.circular(99)),
      beamPaint,
    );

    final Paint sparklePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 15; i++) {
      final double progress = i / 14;
      final double x = beamRect.left + beamRect.width * progress;
      final double wave = math.sin(i * 1.7) * 8;
      sparklePaint.color = Colors.white.withValues(alpha: i.isEven ? .32 : .16);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y + wave),
            width: 3.5 + (i % 3),
            height: 3.5 + (i % 3),
          ),
          const Radius.circular(2),
        ),
        sparklePaint,
      );
    }
  }

  void _drawTrayPedestal(Canvas canvas, Size size) {
    final Rect trayRect = Rect.fromLTWH(
      18,
      size.height * .785,
      math.max(0, size.width - 36),
      math.min(138, size.height * .15),
    );
    final RRect tray = RRect.fromRectAndRadius(
      trayRect,
      const Radius.circular(34),
    );

    final Paint trayGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF20D8FF).withValues(alpha: .16),
          AppTheme.primary.withValues(alpha: .11),
          Colors.transparent,
        ],
        stops: const <double>[0, .58, 1],
      ).createShader(trayRect.inflate(58));
    canvas.drawRRect(tray.inflate(20), trayGlowPaint);

    final Paint trayGlassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0x22FFFFFF),
          Color(0x100D2D86),
          Color(0x22000000),
        ],
        stops: <double>[0, .48, 1],
      ).createShader(trayRect);
    canvas.drawRRect(tray, trayGlassPaint);

    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x66FFFFFF),
          Color(0x9920D8FF),
          Color(0x774A5CFF),
          Color(0x55FFFFFF),
        ],
      ).createShader(trayRect);
    canvas.drawRRect(tray, rimPaint);

    final double slotGap = 12;
    final double slotWidth = (trayRect.width - (slotGap * 4)) / 3;
    final Paint slotPaint = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[
          Color(0x181DDCFF),
          Color(0x0AFFFFFF),
          Color(0x00000000),
        ],
        stops: <double>[0, .55, 1],
      ).createShader(trayRect);
    final Paint slotStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .10);
    for (var i = 0; i < 3; i++) {
      final Rect slot = Rect.fromLTWH(
        trayRect.left + slotGap + (slotWidth + slotGap) * i,
        trayRect.top + 16,
        slotWidth,
        math.max(0, trayRect.height - 32),
      );
      final RRect slotShape = RRect.fromRectAndRadius(
        slot,
        const Radius.circular(24),
      );
      canvas.drawRRect(slotShape, slotPaint);
      canvas.drawRRect(slotShape, slotStrokePaint);
    }
  }

  void _drawBottomCrystalGlow(Canvas canvas, Size size, double shortSide) {
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppTheme.primary.withValues(alpha: .16),
          AppTheme.accent.withValues(alpha: .06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * .50, size.height * .94),
        radius: shortSide * .55,
      ));
    canvas.drawCircle(Offset(size.width * .50, size.height * .94), shortSide * .55, glowPaint);
  }

  void _drawEdgeVignette(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[
          Colors.transparent,
          Color(0x65020B22),
        ],
        stops: <double>[.58, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  Rect _boardRect(Size size, double shortSide) {
    final double boardSize = math.min(size.width - 36, shortSide * .92);
    return Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .515),
      width: boardSize,
      height: boardSize,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
