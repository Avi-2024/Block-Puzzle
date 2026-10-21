import 'dart:math' as math;
import 'dart:math' show Point;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'puzzle_painters.dart';
import 'puzzle_theme.dart';

/// The approved launch composition, drawn with the actual gameplay tiles.
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
      curve: const Interval(.22, .55, curve: Curves.easeOutCubic),
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
      systemNavigationBarColor: Color(0xFF0B153D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF070E2D),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, constraints.maxHeight * .68);
          final height = constraints.maxHeight;
          final titleSize = math.min(76.0, width * .145);
          return Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(painter: _SplashArtPainter(_controller)),
              ),
              Positioned(
                top: height * .55,
                left: 20,
                right: 20,
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MAGIC\nBLOCKS',
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: const Color(0xFFFFFDF8),
                          fontSize: titleSize,
                          height: 1.02,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                          shadows: const [
                            Shadow(
                              color: Color(0xFF1964B6),
                              offset: Offset(0, 1.8),
                            ),
                            Shadow(
                              color: Color(0x99030A29),
                              blurRadius: 14,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: width * .035),
                      Text(
                        'COMBO PUZZLE',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: const Color(0xFFFFD16C),
                          fontSize: math.min(17.0, width * .035),
                          fontWeight: FontWeight.w700,
                          letterSpacing: width * .011,
                          shadows: const [
                            Shadow(color: Color(0x55040B27), blurRadius: 6,
                                offset: Offset(0, 2)),
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

  double _entrance(double start, double end) => Curves.easeOutCubic.transform(
    ((animation.value - start) / (end - start)).clamp(0.0, 1.0),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = math.min(size.width, h * .68);
    final light = _entrance(.04, .62);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF070E2D), Color(0xFF123B86),
            Color(0xFF10276B), Color(0xFF0B153D)],
          stops: [0, .37, .61, 1],
        ).createShader(Offset.zero & size),
    );

    canvas.save();
    canvas.translate((size.width - w) / 2, 0);
    final center = Offset(w * .50, h * .375);
    _glow(canvas, center, w * .65, const Color(0xFF1766EC), .22);
    _glow(canvas, Offset(w * .04, h * .91), w * .55,
        const Color(0xFF712CCB), .25);
    _glow(canvas, Offset(w * .98, h * .94), w * .45,
        const Color(0xFF087BD1), .10);

    // Narrow streaks sit behind the hero and stay clear of the title.
    for (final ray in const [
      (.07, .12, Color(0xFF17C7F3)),
      (.94, .12, Color(0xFF4271FF)),
      (.81, .23, Color(0xFFFFC12E)),
      (.08, .56, Color(0xFFFFC12E)),
      (.94, .55, Color(0xFFA64DF4)),
      (.30, .53, Color(0xFF17C7F3)),
    ]) {
      _ray(canvas, center, Offset(w * ray.$1, h * ray.$2),
          ray.$3, light, w);
    }

    final unit = math.min(w * .105, h * .056);
    _piece(canvas, Offset(w * .405, h * .156), unit, 2, _goldL,
        _entrance(.02, .34));
    _piece(canvas, Offset(w * .158, h * .30), unit, 0, _square,
        _entrance(.07, .39), angle: -.14);
    _piece(canvas, Offset(w * .665, h * .30), unit * .88, 1, _zigzag,
        _entrance(.11, .43), angle: .13);
    _piece(canvas, Offset(w * .335, h * .45), unit * .99, 3, _bar,
        _entrance(.15, .47), angle: .07);

    // Edge decorations remain anchored on taller phones without cropping
    // the hero or stretching any of the gameplay tiles.
    final edge = _entrance(.20, .65);
    _piece(canvas, Offset(-w * .045, h * .86), unit * 1.03, 4,
        _square, edge * .86, angle: -.18);
    _piece(canvas, Offset(w * .78, h * .89), unit, 6, _bar,
        edge * .78, angle: .17);

    for (final dot in const [
      (.31, .185), (.12, .43), (.86, .29), (.69, .40),
      (.79, .46), (.81, .59), (.13, .76), (.33, .88),
    ]) {
      canvas.drawCircle(
        Offset(w * dot.$1, h * dot.$2),
        w * .0016,
        Paint()..color = const Color(0xFF23CFFF).withValues(alpha: .65 * light),
      );
    }
    _sparkle(canvas, center, unit * .46, const Color(0xFFFFE5A8), light);
    _sparkle(canvas, Offset(w * .275, h * .245), unit * .14,
        const Color(0xFF4DE0FF), light);
    _sparkle(canvas, Offset(w * .78, h * .225), unit * .16,
        const Color(0xFFFFDA7D), light);
    _sparkle(canvas, Offset(w * .28, h * .52), unit * .10,
        const Color(0xFFFFDA7D), light);
    _sparkle(canvas, Offset(w * .57, h * .845), unit * .10,
        const Color(0xFFFFDA7D), edge);
    canvas.restore();
  }

  void _piece(Canvas canvas, Offset origin, double unit, int color,
      List<Point<int>> cells, double opacity, {double angle = 0}) {
    if (opacity <= 0) return;
    canvas.save();
    canvas.translate(origin.dx, origin.dy + unit * .10 * (1 - opacity));
    canvas.rotate(angle);
    final silhouette = Path();
    for (final cell in cells) {
      silhouette.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cell.x * unit, cell.y * unit, unit * .96, unit * .96),
        Radius.circular(unit * .065),
      ));
    }
    canvas.drawShadow(silhouette,
        Colors.black.withValues(alpha: .36 * opacity), unit * .13, false);
    _glow(canvas, Offset(unit, unit), unit * 2.0,
        _palette.colors[color], .075 * opacity);
    for (final cell in cells) {
      paintTile(
        canvas,
        Rect.fromLTWH(cell.x * unit, cell.y * unit, unit * .96, unit * .96),
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

  void _ray(Canvas canvas, Offset center, Offset end, Color color,
      double opacity, double width) {
    final direction = end - center;
    final length = direction.distance;
    if (length == 0 || opacity <= 0) return;
    final normal = Offset(-direction.dy, direction.dx) / length;
    final start = center + direction * .12;
    final tip = center + direction * .48;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(tip.dx + normal.dx * width * .003,
          tip.dy + normal.dy * width * .003)
      ..lineTo(end.dx, end.dy)
      ..lineTo(tip.dx - normal.dx * width * .003,
          tip.dy - normal.dy * width * .003)
      ..close();
    canvas.drawPath(path, Paint()..shader = ui.Gradient.linear(start, end, [
      color.withValues(alpha: 0),
      color.withValues(alpha: .55 * opacity),
      color.withValues(alpha: 0),
    ], const [0, .45, 1]));
  }

  void _sparkle(Canvas canvas, Offset center, double radius, Color color,
      double opacity) {
    _glow(canvas, center, radius * 2.8, color, .25 * opacity);
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
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..shader = LinearGradient(
        colors: [const Color(0xFFFFF8DF), color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius)));
  }

  @override
  bool shouldRepaint(covariant _SplashArtPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
