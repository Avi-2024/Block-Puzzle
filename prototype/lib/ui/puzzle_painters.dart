import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/puzzle.dart';
import 'puzzle_theme.dart';

const puzzleColors = <Color>[
  Color(0xFF5297DF),
  Color(0xFF65BFA4),
  Color(0xFFEEC16A),
  Color(0xFFE78473),
  Color(0xFFA592DD),
];
const puzzleLight = <Color>[
  Color(0xFF91C8FF),
  Color(0xFF9CE9CB),
  Color(0xFFFFE09A),
  Color(0xFFFFB29C),
  Color(0xFFD1C0FF),
];
const puzzleDark = <Color>[
  Color(0xFF3471B9),
  Color(0xFF3C9380),
  Color(0xFFBC8B3D),
  Color(0xFFB65C57),
  Color(0xFF7969AF),
];
double _clamp(double v) => v.clamp(0.0, 1.0);
double _ease(double t) => 1 - math.pow(1 - t, 3).toDouble();
double _back(double t) =>
    1 + 2.70158 * math.pow(t - 1, 3) + 1.70158 * math.pow(t - 1, 2);

void paintTile(
  Canvas canvas,
  Rect rect,
  int color, {
  double opacity = 1,
  double scale = 1,
  PuzzlePalette palette = PuzzlePalette.ocean,
}) {
  if (opacity <= 0) return;
  final r = Rect.fromCenter(
    center: rect.center,
    width: rect.width * scale,
    height: rect.height * scale,
  );
  final radius = Radius.circular(r.width * .115);
  canvas.drawRRect(
    RRect.fromRectAndRadius(r.shift(Offset(0, rect.width * .06)), radius),
    Paint()..color = palette.tileDark(color).withValues(alpha: opacity),
  );
  final shader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      palette.tileLight(color).withValues(alpha: opacity),
      palette.colors[color].withValues(alpha: opacity),
      palette.colors[color].withValues(alpha: opacity),
    ],
    stops: const [0, .3, 1],
  ).createShader(r);
  canvas.drawRRect(
    RRect.fromRectAndRadius(r, radius),
    Paint()..shader = shader,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(r.deflate(.7), radius),
    Paint()
      ..color = Colors.white.withValues(alpha: .24 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(r.left + 4, r.top + 3, math.max(2, r.width - 8), 2),
      const Radius.circular(1),
    ),
    Paint()..color = Colors.white.withValues(alpha: .09 * opacity),
  );
}

class PiecePainter extends CustomPainter {
  PiecePainter(
    this.piece, {
    this.opacity = 1,
    this.palette = PuzzlePalette.ocean,
  });
  final PuzzlePalette palette;
  final Piece piece;
  final double opacity;
  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width / piece.width, size.height / piece.height);
    for (final c in piece.cells) {
      paintTile(
        canvas,
        Rect.fromLTWH(c.x * unit, c.y * unit, unit * .895, unit * .895),
        piece.color,
        opacity: opacity,
        palette: palette,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PiecePainter old) =>
      old.piece != piece || old.opacity != opacity || old.palette != palette;
}

class RewardStyle {
  const RewardStyle(
    this.title,
    this.caption,
    this.light,
    this.dark,
    this.fontSize,
    this.duration,
  );
  final String title;
  final String caption;
  final Color light;
  final Color dark;
  final double fontSize;
  final int duration;
  static RewardStyle forMove(PuzzleMove move) {
    final chain = move.state.combo;
    if (chain <= 1) {
      return const RewardStyle(
        'NICE!',
        'CLEAN MOVE',
        Color(0xFFEDFFF6),
        Color(0xFF81DBB8),
        36,
        1180,
      );
    }
    if (chain == 2) {
      return const RewardStyle(
        'COMBO ×2',
        'TWO IN A ROW',
        Color(0xFFEAFFFA),
        Color(0xFF5CDBBC),
        34,
        1480,
      );
    }
    if (chain == 3) {
      return const RewardStyle(
        'AMAZING!',
        'COMBO ×3',
        Color(0xFFFFF4BD),
        Color(0xFFFFC34F),
        37,
        1550,
      );
    }
    return RewardStyle(
      'UNSTOPPABLE!',
      'COMBO ×$chain${move.allClear ? ' · ALL CLEAR' : ''}',
      const Color(0xFFFFF3B4),
      const Color(0xFFFF977D),
      29,
      1750,
    );
  }
}

class PuzzleBoardPainter extends CustomPainter {
  PuzzleBoardPainter({
    required this.board,
    required this.animation,
    required this.reduceMotion,
    this.move,
    this.ghost,
    this.ghostX = 0,
    this.ghostY = 0,
    this.palette = PuzzlePalette.ocean,
    this.refinedFrame = false,
  }) : super(repaint: animation);
  final List<int> board;
  final bool refinedFrame;
  final PuzzlePalette palette;
  final Animation<double> animation;
  final bool reduceMotion;
  final PuzzleMove? move;
  final Piece? ghost;
  final int ghostX;
  final int ghostY;
  double get elapsed => animation.value * 1750;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320);
    final bg = RRect.fromRectAndRadius(
      refinedFrame
          ? const Rect.fromLTWH(4, 4, 308, 308)
          : const Rect.fromLTWH(0, 0, 320, 320),
      Radius.circular(refinedFrame ? 8 : 15),
    );
    canvas.drawRRect(bg, Paint()..color = palette.panel);
    final effect = move;
    final visible =
        effect != null &&
            effect.lines > 0 &&
            elapsed < (reduceMotion ? 100 : 420)
        ? effect.beforeClear
        : board;
    for (var i = 0; i < 64; i++) {
      final x = 8.0 + i % 8 * 38, y = 8.0 + i ~/ 8 * 38;
      final rect = Rect.fromLTWH(x, y, 34, 34);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(refinedFrame ? 3 : 4)),
        Paint()..color = palette.cell,
      );
      final color = visible[i];
      if (color < 0) continue;
      var opacity = 1.0, scale = 1.0;
      if (!reduceMotion && effect != null) {
        if (effect.cleared.contains(i)) {
          final axis = effect.rows.contains(i ~/ 8) ? i % 8 : i ~/ 8;
          final t = _clamp((elapsed - axis * 15 - 75) / 210);
          opacity = 1 - t;
          scale = 1 - .68 * _ease(t);
        } else if (effect.placed.contains(i) && elapsed < 180) {
          scale = 1 + .055 * math.sin(elapsed / 180 * math.pi);
        }
      }
      paintTile(
        canvas,
        rect,
        color,
        opacity: opacity,
        scale: scale,
        palette: palette,
      );
    }
    if (ghost case final piece?) {
      for (final c in piece.cells) {
        final rect = Rect.fromLTWH(
          8 + (ghostX + c.x) * 38.0,
          8 + (ghostY + c.y) * 38.0,
          34,
          34,
        );
        paintTile(canvas, rect, piece.color, opacity: .32, palette: palette);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(.5), const Radius.circular(4)),
          Paint()
            ..color = palette.accent.withValues(alpha: .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
    if (effect != null && effect.lines > 0) {
      if (!reduceMotion) _clearFx(canvas, effect);
      _reward(canvas, effect);
    }
    canvas.restore();
  }

  void _clearFx(Canvas canvas, PuzzleMove effect) {
    final reward = RewardStyle.forMove(effect);
    if (elapsed < 420) {
      final x = -50 + _clamp(elapsed / 340) * 430;
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xADFFF7D3),
            Colors.transparent,
          ],
          stops: const [0, .65, 1],
        ).createShader(Rect.fromLTWH(x - 65, 0, 100, 320));
      for (final row in effect.rows) {
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(7, 6 + row * 38.0, 306, 39));
        canvas.drawRect(Rect.fromLTWH(x - 65, 6 + row * 38.0, 100, 39), paint);
        canvas.restore();
      }
      for (final col in effect.columns) {
        canvas.save();
        canvas.translate(320, 0);
        canvas.rotate(math.pi / 2);
        canvas.clipRect(Rect.fromLTWH(7, 6 + (7 - col) * 38.0, 306, 39));
        canvas.drawRect(
          Rect.fromLTWH(x - 65, 6 + (7 - col) * 38.0, 100, 39),
          paint,
        );
        canvas.restore();
      }
    }
    if (elapsed < 650) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(2, 2, 316, 316),
          const Radius.circular(14),
        ),
        Paint()
          ..color = reward.dark.withValues(alpha: (1 - elapsed / 650) * .48)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    var index = 0;
    for (final cell in effect.cleared) {
      for (var j = 0; j < 3; j++) {
        final i = index * 3 + j,
            t = (elapsed - (cell % 8) * 15) / (580 + (i % 3) * 100);
        if (t < 0 || t >= 1) continue;
        final center = Offset(25 + (cell % 8) * 38.0, 25 + (cell ~/ 8) * 38.0);
        final offset = Offset(
          math.sin(i * 2.7) * (28 + math.min(effect.state.combo, 4) * 5) * t,
          (-30 - math.cos(i * 1.9).abs() * 53) * t + 55 * t * t,
        );
        final alpha = math.pow(1 - t, 1.25).toDouble() * .9;
        final color = i % 3 == 0
            ? reward.light
            : palette.tileLight(effect.beforeClear[cell]);
        if (i % 5 == 0) {
          _spark(
            canvas,
            center + offset,
            3.2,
            color.withValues(alpha: alpha),
            t * 3,
          );
        } else {
          canvas.save();
          canvas.translate(center.dx + offset.dx, center.dy + offset.dy);
          canvas.rotate(t * (i.isEven ? 3 : -3));
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: 2.0 + i % 3,
                height: 2.0 + i % 3,
              ),
              const Radius.circular(1),
            ),
            Paint()..color = color.withValues(alpha: alpha),
          );
          canvas.restore();
        }
      }
      if (index % 4 == 0) {
        final t = (elapsed - 170 - (index % 4) * 55) / 680;
        if (t >= 0 && t < 1) {
          final e = t * t,
              start = Offset(25 + (cell % 8) * 38.0, 25 + (cell ~/ 8) * 38.0);
          final position =
              start * ((1 - e) * (1 - e)) +
              (start - const Offset(35, 90)) * (2 * (1 - e) * e) +
              const Offset(28, -12) * (e * e);
          canvas.drawCircle(
            position,
            2.2,
            Paint()
              ..color = reward.light.withValues(
                alpha: math.sin(t * math.pi) * .85,
              ),
          );
        }
      }
      index++;
    }
  }

  void _spark(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double angle,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final r = radius;
    final path = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(r * .22, -r * .22, r, 0)
      ..quadraticBezierTo(r * .22, r * .22, 0, r)
      ..quadraticBezierTo(-r * .22, r * .22, -r, 0)
      ..quadraticBezierTo(-r * .22, -r * .22, 0, -r);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  TextPainter _text(String text, TextStyle style) => TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(fontFamily: style.fontFamily ?? 'Roboto'),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  void _reward(Canvas canvas, PuzzleMove effect) {
    final cfg = RewardStyle.forMove(effect), ms = elapsed;
    if (ms >= cfg.duration) return;
    final fade = _clamp(ms / 70) * _clamp((cfg.duration - ms) / 260);
    final enter = _clamp(ms / 420),
        exit = _clamp((ms - cfg.duration + 260) / 260);
    canvas.saveLayer(
      const Rect.fromLTWH(0, 0, 320, 180),
      Paint()..color = Colors.white.withValues(alpha: fade),
    );
    canvas.drawRect(
      const Rect.fromLTWH(20, 0, 280, 180),
      Paint()
        ..shader = RadialGradient(
          colors: [
            cfg.dark.withValues(alpha: .15),
            cfg.dark.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(35, -45, 250, 250)),
    );
    if (!reduceMotion && effect.state.combo > 1) {
      final wave = _clamp(ms / 630);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(160, 72),
          width: 60 + 200 * _ease(wave),
          height: 24 + 62 * _ease(wave),
        ),
        Paint()
          ..color = cfg.dark.withValues(alpha: (1 - wave) * .36)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      for (var i = 0; i < math.min(effect.state.combo, 4) * 3; i++) {
        final a = i * 2.399,
            d = 40 + _ease(_clamp(ms / 650)) * (33 + (i % 3) * 12),
            life =
                _clamp((ms - i * 18) / 160) *
                _clamp((1050 - ms + i * 12) / 400);
        _spark(
          canvas,
          Offset(160 + math.cos(a) * d * 1.35, 72 + math.sin(a) * d * .64),
          2 + (i % 3) * 1.2,
          cfg.light.withValues(alpha: life * .85),
          a + ms * .001,
        );
      }
    }
    canvas.translate(
      160,
      reduceMotion ? 76 : 76 + 10 * (1 - _ease(enter)) - 12 * _ease(exit),
    );
    final scale = reduceMotion ? 1.0 : .76 + .24 * _back(enter);
    canvas.scale(scale);
    canvas.rotate(reduceMotion ? 0 : -.052 + .075 * (1 - _ease(enter)));
    final style = TextStyle(
      fontSize: cfg.fontSize,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: -.5,
      height: 1,
      fontFamily: 'Roboto',
    );
    final title = _text(cfg.title, style),
        fit = math.min(1.0, 282 / title.width);
    canvas.save();
    canvas.scale(fit);
    canvas.translate(-title.width / 2, -title.height);
    final stroke = _text(
      cfg.title,
      style.copyWith(
        foreground: Paint()
          ..color = const Color(0xFF0B2949)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeJoin = StrokeJoin.round,
      ),
    );
    stroke.paint(canvas, const Offset(0, 3));
    final fill = _text(
      cfg.title,
      style.copyWith(
        foreground: Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cfg.light, cfg.light, cfg.dark],
            stops: const [0, .55, 1],
          ).createShader(Rect.fromLTWH(0, 0, title.width, title.height)),
      ),
    );
    fill.paint(canvas, Offset.zero);
    canvas.restore();
    canvas.rotate(reduceMotion ? 0 : .052);
    final caption = _text(
      cfg.caption,
      TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: palette.ink,
        height: 1,
      ),
    );
    caption.paint(canvas, Offset(-caption.width / 2, 12));
    final points = _text(
      '+${effect.points}',
      TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: palette.light ? palette.ink : cfg.light,
        height: 1,
      ),
    );
    points.paint(canvas, Offset(-points.width / 2, 33));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PuzzleBoardPainter old) =>
      old.board != board ||
      old.move != move ||
      old.ghost != ghost ||
      old.ghostX != ghostX ||
      old.ghostY != ghostY ||
      old.reduceMotion != reduceMotion ||
      old.refinedFrame != refinedFrame ||
      old.palette != palette;
}
