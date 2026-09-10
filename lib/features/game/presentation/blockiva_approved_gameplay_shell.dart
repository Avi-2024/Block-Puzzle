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
    glow(
      Offset(size.width * .50, size.height * .34),
      shortSide * .62,
      const Color(0xFF8C60FF),
      .26,
    );
    glow(
      Offset(size.width * .12, size.height * .16),
      shortSide * .42,
      const Color(0xFF20D8FF),
      .20,
    );
    glow(
      Offset(size.width * .92, size.height * .82),
      shortSide * .48,
      const Color(0xFFFF6CC8),
      .16,
    );
    glow(
      Offset(size.width * .48, size.height * .86),
      shortSide * .40,
      const Color(0xFF38F2A0),
      .10,
    );
  }

  void _drawFloatingCubes(Canvas canvas, Size size) {
    final Paint cubePaint = Paint()..style = PaintingStyle.fill;
    final Paint cubeStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var i = 0; i < 14; i++) {
      final double seed = i * 23.0;
      final double x = (math.sin(seed) * .5 + .5) * size.width;
      final double y = size.height *
          (.13 + ((math.cos(seed * .83) * .5 + .5) * .77));
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
      particlePaint.color = Colors.white.withValues(
        alpha: i.isEven ? .12 : .052,
      );
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
    _drawLogoGlowShelf(canvas, size);
    _drawTopHudGlassAnchors(canvas, size);
    _drawHudButtonRings(canvas, size);
    _drawHeroScoreAura(canvas, size, shortSide);
    _drawComboBadgeStage(canvas, size);
    _drawBoardHeroFrame(canvas, size, shortSide);
    _drawBoardTargetLattice(canvas, size, shortSide);
    _drawClearEnergyPreview(canvas, size, shortSide);
    _drawTrayPedestal(canvas, size);
    _drawTrayLiftCues(canvas, size);
    _drawBottomCrystalGlow(canvas, size, shortSide);
    _drawEdgeVignette(canvas, size);
  }

  void _drawLogoGlowShelf(Canvas canvas, Size size) {
    final Rect shelfRect = Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .085),
      width: math.min(size.width * .66, 310),
      height: 86,
    );
    final Paint shelfGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: .13),
          const Color(0xFF20D8FF).withValues(alpha: .09),
          AppTheme.primary.withValues(alpha: .04),
          Colors.transparent,
        ],
        stops: const <double>[0, .40, .68, 1],
      ).createShader(shelfRect.inflate(48));
    canvas.drawOval(shelfRect.inflate(40), shelfGlowPaint);

    final Paint shinePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x00000000),
          Color(0x33FFFFFF),
          Color(0x00000000),
        ],
      ).createShader(shelfRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: shelfRect.center.translate(0, shelfRect.height * .33),
          width: shelfRect.width * .72,
          height: 3,
        ),
        const Radius.circular(99),
      ),
      shinePaint,
    );
  }

  void _drawTopHudGlassAnchors(Canvas canvas, Size size) {
    final double top = size.height * .055;
    final Rect leftPill = Rect.fromLTWH(16, top + 54, 118, 48);
    final Rect rightPill = Rect.fromLTWH(size.width - 134, top + 54, 118, 48);
    final RRect left = RRect.fromRectAndRadius(leftPill, const Radius.circular(18));
    final RRect right = RRect.fromRectAndRadius(rightPill, const Radius.circular(18));

    final Paint glassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0x26FFFFFF),
          Color(0x111DDCFF),
          Color(0x19000000),
        ],
      ).createShader(leftPill.expandToInclude(rightPill));
    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x66FFFFFF),
          Color(0x7732B6FF),
          Color(0x55FFFFFF),
        ],
      ).createShader(leftPill.expandToInclude(rightPill));

    for (final RRect pill in <RRect>[left, right]) {
      canvas.drawRRect(pill, glassPaint);
      canvas.drawRRect(pill, rimPaint);
    }

    final Paint orbPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppTheme.warning.withValues(alpha: .36),
          AppTheme.warning.withValues(alpha: .10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: leftPill.centerLeft, radius: 28));
    canvas.drawCircle(leftPill.centerLeft.translate(22, 0), 28, orbPaint);

    final Paint trophyGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppTheme.warning.withValues(alpha: .24),
          AppTheme.accent.withValues(alpha: .08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: rightPill.center, radius: 46));
    canvas.drawCircle(rightPill.center, 46, trophyGlowPaint);
  }

  void _drawHudButtonRings(Canvas canvas, Size size) {
    final double centerY = math.max(28, size.height * .056);
    final List<Offset> centers = <Offset>[
      Offset(36, centerY),
      Offset(size.width - 36, centerY),
    ];
    final Paint haloPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: .14),
          const Color(0xFF20D8FF).withValues(alpha: .09),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * .5, centerY), radius: 78));
    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45;
    final Paint shinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .34);

    for (final Offset center in centers) {
      canvas.drawCircle(center, 31, haloPaint);
      ringPaint.shader = SweepGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: .62),
          const Color(0xFF20D8FF).withValues(alpha: .52),
          AppTheme.primary.withValues(alpha: .22),
          Colors.white.withValues(alpha: .62),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 23));
      canvas.drawCircle(center, 23.5, ringPaint);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 18.5),
        -math.pi * .76,
        math.pi * .32,
        false,
        shinePaint,
      );
    }
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

  void _drawComboBadgeStage(Canvas canvas, Size size) {
    final Rect badgeRect = Rect.fromCenter(
      center: Offset(size.width * .50, math.max(104, size.height * .145)),
      width: math.min(size.width * .54, 230),
      height: 42,
    );
    final RRect badge = RRect.fromRectAndRadius(badgeRect, const Radius.circular(99));
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppTheme.warning.withValues(alpha: .16),
          AppTheme.accent.withValues(alpha: .08),
          Colors.transparent,
        ],
      ).createShader(badgeRect.inflate(44));
    final Paint glassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0x16FFFFFF),
          Color(0x091DDCFF),
          Color(0x00000000),
        ],
      ).createShader(badgeRect);
    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x00FFFFFF),
          Color(0x55FFE04F),
          Color(0x33FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(badgeRect);

    canvas.drawRRect(badge.inflate(20), glowPaint);
    canvas.drawRRect(badge, glassPaint);
    canvas.drawRRect(badge, rimPaint);

    final Paint sparklePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 9; i++) {
      final double progress = i / 8;
      final double x = badgeRect.left + badgeRect.width * progress;
      final double y = badgeRect.center.dy + math.sin(i * 1.3) * 12;
      sparklePaint.color = Colors.white.withValues(alpha: i.isEven ? .20 : .10);
      canvas.drawCircle(Offset(x, y), i.isEven ? 1.35 : .95, sparklePaint);
    }
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

    final Paint innerSparkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x0020D8FF),
          Color(0x7720D8FF),
          Color(0x33FFFFFF),
          Color(0x00FF6CC8),
        ],
      ).createShader(boardRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.inflate(5), const Radius.circular(24)),
      innerSparkPaint,
    );
  }

  void _drawBoardTargetLattice(Canvas canvas, Size size, double shortSide) {
    final Rect boardRect = _boardRect(size, shortSide).deflate(9);
    final double cellSize = boardRect.width / 8;
    final Paint railPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .72
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0x00FFFFFF),
          Color(0x1DFFFFFF),
          Color(0x0920D8FF),
          Color(0x00FFFFFF),
        ],
        stops: <double>[0, .18, .74, 1],
      ).createShader(boardRect);

    for (var i = 1; i < 8; i++) {
      final double offset = cellSize * i;
      canvas.drawLine(
        Offset(boardRect.left + offset, boardRect.top),
        Offset(boardRect.left + offset, boardRect.bottom),
        railPaint,
      );
      canvas.drawLine(
        Offset(boardRect.left, boardRect.top + offset),
        Offset(boardRect.right, boardRect.top + offset),
        railPaint,
      );
    }

    final Paint nodePaint = Paint()..style = PaintingStyle.fill;
    for (var row = 1; row < 8; row += 2) {
      for (var col = 1; col < 8; col += 2) {
        final bool accentNode = (row + col).isEven;
        nodePaint.color = (accentNode ? Colors.white : const Color(0xFF20D8FF))
            .withValues(alpha: accentNode ? .070 : .045);
        canvas.drawCircle(
          Offset(boardRect.left + cellSize * col, boardRect.top + cellSize * row),
          accentNode ? 1.55 : 1.15,
          nodePaint,
        );
      }
    }
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
          const Color(0xFF20D8FF).withValues(alpha: .22),
          AppTheme.primary.withValues(alpha: .13),
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
          Color(0x2EFFFFFF),
          Color(0x151DDCFF),
          Color(0x26000000),
        ],
        stops: <double>[0, .48, 1],
      ).createShader(trayRect);
    canvas.drawRRect(tray, trayGlassPaint);

    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x77FFFFFF),
          Color(0xBB20D8FF),
          Color(0x884A5CFF),
          Color(0x66FFFFFF),
        ],
      ).createShader(trayRect);
    canvas.drawRRect(tray, rimPaint);

    final double slotGap = 12;
    final double slotWidth = (trayRect.width - (slotGap * 4)) / 3;
    final Paint slotPaint = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[
          Color(0x221DDCFF),
          Color(0x0EFFFFFF),
          Color(0x00000000),
        ],
        stops: <double>[0, .55, 1],
      ).createShader(trayRect);
    final Paint slotStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withValues(alpha: .13);
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

  void _drawTrayLiftCues(Canvas canvas, Size size) {
    final Rect trayRect = Rect.fromLTWH(
      18,
      size.height * .785,
      math.max(0, size.width - 36),
      math.min(138, size.height * .15),
    );
    final double slotGap = 12;
    final double slotWidth = (trayRect.width - (slotGap * 4)) / 3;
    final Paint shadowPaint = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[
          Color(0x34000000),
          Color(0x11000000),
          Color(0x00000000),
        ],
      ).createShader(trayRect);
    final Paint liftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x0020D8FF),
          Color(0x5520D8FF),
          Color(0x44FFFFFF),
          Color(0x0020D8FF),
        ],
        stops: <double>[0, .28, .58, 1],
      ).createShader(trayRect);

    for (var i = 0; i < 3; i++) {
      final Rect slot = Rect.fromLTWH(
        trayRect.left + slotGap + (slotWidth + slotGap) * i,
        trayRect.top + 18,
        slotWidth,
        math.max(0, trayRect.height - 34),
      );
      final Rect shadow = Rect.fromCenter(
        center: Offset(slot.center.dx, slot.bottom - 8),
        width: slot.width * .72,
        height: 16,
      );
      canvas.drawOval(shadow, shadowPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(slot.center.dx, slot.top + 2),
            width: slot.width * .68,
            height: 2.8,
          ),
          const Radius.circular(99),
        ),
        liftPaint,
      );
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
    canvas.drawCircle(
      Offset(size.width * .50, size.height * .94),
      shortSide * .55,
      glowPaint,
    );
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
