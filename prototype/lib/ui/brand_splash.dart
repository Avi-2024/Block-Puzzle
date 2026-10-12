import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'puzzle_painters.dart';
import 'puzzle_theme.dart';

/// A short launch scene using the same tile renderer and Ocean colors as play.
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    )..addStatusListener(_onStatus);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.17, .7, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF080D34),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF080D34),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final titleSize = math.min(46.0, width * .118);
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _SplashArtPainter(_controller)),
              Positioned(
                top: height * .54,
                left: 12,
                right: 12,
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MAGIC\nBLOCKS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          height: .91,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                          shadows: const [
                            Shadow(
                              color: Color(0xFF3266E9),
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'COMBO PUZZLE',
                        style: TextStyle(
                          color: const Color(0xFFFFD577),
                          fontSize: math.min(13.0, width * .033),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3.7,
                          shadows: const [
                            Shadow(color: Color(0x77E89B2E), blurRadius: 9),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _SplashArtPainter extends CustomPainter {
  _SplashArtPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;
  static const _palette = PuzzlePalette.ocean;
  static const _goldL = [Point(0, 0), Point(0, 1), Point(1, 1)];
  static const _square = [Point(0, 0), Point(1, 0), Point(0, 1), Point(1, 1)];
  static const _zigzag = [Point(0, 0), Point(1, 0), Point(1, 1), Point(2, 1)];
  static const _bar = [Point(0, 0), Point(1, 0), Point(2, 0)];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final entrance = Curves.easeOutCubic.transform(animation.value);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060B2E), Color(0xFF102881), Color(0xFF070C37)],
          stops: [0, .56, 1],
        ).createShader(Offset.zero & size),
    );

    _glow(canvas, Offset(w * .50, h * .38), w * .72,
        const Color(0xFF1354EA), .36);
    _glow(canvas, Offset(w * .48, h * .95), w * .68,
        const Color(0xFF6937B7), .23);
    _ray(canvas, Offset(w * .49, h * .36), Offset(-w * .28, h * .08),
        const Color(0xFF2785FF));
    _ray(canvas, Offset(w * .51, h * .36), Offset(w * 1.22, h * .06),
        const Color(0xFF5E54DB));
    _ray(canvas, Offset(w * .50, h * .37), Offset(w * .16, h * .68),
        const Color(0xFF3477F9));
    _ray(canvas, Offset(w * .50, h * .37), Offset(w * .91, h * .68),
        const Color(0xFF7558C7));

    final unit = math.min(w * .116, h * .056);
    _piece(canvas, Offset(w * .43, h * .16), unit, 2, _goldL, entrance);
    _piece(canvas, Offset(w * .20, h * .30), unit, 0, _square, entrance,
        angle: -.14);
    _piece(canvas, Offset(w * .70, h * .30), unit * .86, 1, _zigzag,
        entrance, angle: .13);
    _piece(canvas, Offset(w * .34, h * .45), unit * .95, 3, _bar, entrance,
        angle: .09);

    // The lower edge echoes the approved art with front-facing game tiles.
    final bottomUnit = unit * .90;
    _piece(canvas, Offset(-w * .04, h * .80), bottomUnit, 0, _square,
        entrance * .86);
    _piece(canvas, Offset(w * .18, h * .90), bottomUnit, 4, _square,
        entrance * .78);
    _piece(canvas, Offset(w * .72, h * .85), bottomUnit, 3, _goldL,
        entrance * .88, angle: -.17);
    _piece(canvas, Offset(w * .92, h * .78), bottomUnit, 1, _bar,
        entrance * .72);

    for (var i = 0; i < 20; i++) {
      final x = ((i * 73 + 19) % 97) / 97.0 * w;
      final y = ((i * 47 + 11) % 89) / 89.0 * h;
      canvas.drawCircle(
        Offset(x, y),
        i.isEven ? 1.0 : .65,
        Paint()..color = Colors.white.withValues(alpha: .15 + .16 * entrance),
      );
    }
    _sparkle(canvas, Offset(w * .50, h * .37), unit * .52,
        const Color(0xFFFFF6DC), entrance);
    _sparkle(canvas, Offset(w * .30, h * .25), unit * .14,
        const Color(0xFF8CE8FF), entrance);
    _sparkle(canvas, Offset(w * .80, h * .22), unit * .16,
        const Color(0xFFFFD577), entrance);
    _sparkle(canvas, Offset(w * .52, h * .91), unit * .12,
        const Color(0xFFFFD577), entrance);
  }

  void _piece(Canvas canvas, Offset origin, double unit, int color,
      List<Point<int>> cells, double opacity, {double angle = 0}) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);
    _glow(canvas, Offset(unit * 1.2, unit * .85), unit * 2.6,
        _palette.colors[color], .21 * opacity);
    for (final cell in cells) {
      paintTile(
        canvas,
        Rect.fromLTWH(cell.x * unit, cell.y * unit, unit * .92, unit * .92),
        color,
        palette: _palette,
        opacity: opacity,
      );
    }
    canvas.restore();
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color,
      double alpha) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  void _ray(Canvas canvas, Offset from, Offset to, Color color) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy)
      ..lineTo(to.dx + 12, to.dy + 9)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: .09));
  }

  void _sparkle(Canvas canvas, Offset center, double radius, Color color,
      double opacity) {
    _glow(canvas, center, radius * 2.8, color, .40 * opacity);
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx + radius * .18, center.dy - radius * .18,
          center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx + radius * .18, center.dy + radius * .18,
          center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx - radius * .18, center.dy + radius * .18,
          center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx - radius * .18, center.dy - radius * .18,
          center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: opacity));
  }

  @override
  bool shouldRepaint(covariant _SplashArtPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
