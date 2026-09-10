import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Lightweight, paint-only motion polish for the approved gameplay direction.
///
/// This layer stays completely outside the game engine. It adds slow shimmer,
/// board focus, and tray energy so the screen feels more alive while preserving
/// scoring, placement, drag math, ads, and persistence behavior.
class BlockivaGameplayMotionLayer extends StatefulWidget {
  const BlockivaGameplayMotionLayer({required this.child, super.key});

  final Widget child;

  @override
  State<BlockivaGameplayMotionLayer> createState() =>
      _BlockivaGameplayMotionLayerState();
}

class _BlockivaGameplayMotionLayerState extends State<BlockivaGameplayMotionLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  return CustomPaint(
                    painter: _BlockivaGameplayMotionPainter(
                      phase: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlockivaGameplayMotionPainter extends CustomPainter {
  const _BlockivaGameplayMotionPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final double shortSide = math.min(size.width, size.height);
    final Rect boardRect = _boardRect(size, shortSide);
    final Rect trayRect = _trayRect(size);

    _drawBoardSweep(canvas, boardRect);
    _drawScorePulse(canvas, size, shortSide);
    _drawTrayEnergy(canvas, trayRect);
    _drawFloatingRewardDust(canvas, size);
  }

  void _drawBoardSweep(Canvas canvas, Rect boardRect) {
    final double sweepX = boardRect.left + boardRect.width * phase;
    final Rect sweepRect = Rect.fromCenter(
      center: Offset(sweepX, boardRect.center.dy),
      width: boardRect.width * .28,
      height: boardRect.height + 48,
    );
    final Paint sweepPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          Color(0x00000000),
          Color(0x1020D8FF),
          Color(0x20FFFFFF),
          Color(0x1020D8FF),
          Color(0x00000000),
        ],
        stops: <double>[0, .28, .50, .72, 1],
      ).createShader(sweepRect);

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(boardRect.inflate(20), const Radius.circular(34)),
    );
    canvas.drawRect(sweepRect, sweepPaint);
    canvas.restore();
  }

  void _drawScorePulse(Canvas canvas, Size size, double shortSide) {
    final double pulse = .5 + (.5 * math.sin(phase * math.pi * 2));
    final Offset center = Offset(size.width * .50, size.height * .185);
    final double radius = shortSide * (.18 + pulse * .035);
    final Paint pulsePaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          AppTheme.warning.withValues(alpha: .10 + pulse * .045),
          AppTheme.primary.withValues(alpha: .045 + pulse * .025),
          Colors.transparent,
        ],
        stops: const <double>[0, .42, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, pulsePaint);
  }

  void _drawTrayEnergy(Canvas canvas, Rect trayRect) {
    final Paint glowPaint = Paint();
    final double slotGap = 12;
    final double slotWidth = (trayRect.width - (slotGap * 4)) / 3;

    for (var index = 0; index < 3; index++) {
      final double localPhase = (phase + index * .18) % 1;
      final Rect slot = Rect.fromLTWH(
        trayRect.left + slotGap + (slotWidth + slotGap) * index,
        trayRect.top + 18,
        slotWidth,
        math.max(0, trayRect.height - 34),
      );
      final Offset center = Offset(
        slot.center.dx,
        slot.top + slot.height * (.18 + .56 * localPhase),
      );
      glowPaint.shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF20D8FF).withValues(alpha: .11),
          AppTheme.primary.withValues(alpha: .05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: slot.width * .58));
      canvas.drawCircle(center, slot.width * .58, glowPaint);
    }
  }

  void _drawFloatingRewardDust(Canvas canvas, Size size) {
    final Paint dustPaint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 18; index++) {
      final double seed = index * 37.0;
      final double travel = (phase + index * .061) % 1;
      final double x = (math.sin(seed) * .5 + .5) * size.width;
      final double y = size.height * (.72 - travel * .42);
      final double opacity = math.sin(travel * math.pi).clamp(0, 1).toDouble();
      final Color color = AppTheme.piecePalette[index % AppTheme.piecePalette.length];
      dustPaint.color = color.withValues(alpha: opacity * .10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y),
            width: 3 + (index % 3),
            height: 3 + (index % 3),
          ),
          const Radius.circular(2),
        ),
        dustPaint,
      );
    }
  }

  Rect _boardRect(Size size, double shortSide) {
    final double boardSize = math.min(size.width - 36, shortSide * .92);
    return Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .515),
      width: boardSize,
      height: boardSize,
    );
  }

  Rect _trayRect(Size size) {
    return Rect.fromLTWH(
      18,
      size.height * .785,
      math.max(0, size.width - 36),
      math.min(138, size.height * .15),
    );
  }

  @override
  bool shouldRepaint(covariant _BlockivaGameplayMotionPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
