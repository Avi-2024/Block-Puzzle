import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../game/puzzle.dart';
import '../game/move_feedback.dart';
import 'puzzle_theme.dart';

// Original unit-space bevel geometry. Reuse paths and shaders while dragging.
const _bevel = .105;
final _topBevel = Path()
  ..moveTo(0, 0)
  ..lineTo(1, 0)
  ..lineTo(1 - _bevel, _bevel)
  ..lineTo(_bevel, _bevel)
  ..close();
final _leftBevel = Path()
  ..moveTo(0, 0)
  ..lineTo(_bevel, _bevel)
  ..lineTo(_bevel, 1 - _bevel)
  ..lineTo(0, 1)
  ..close();
final _bottomBevel = Path()
  ..moveTo(0, 1)
  ..lineTo(_bevel, 1 - _bevel)
  ..lineTo(1 - _bevel, 1 - _bevel)
  ..lineTo(1, 1)
  ..close();
final _rightBevel = Path()
  ..moveTo(1, 0)
  ..lineTo(1, 1)
  ..lineTo(1 - _bevel, 1 - _bevel)
  ..lineTo(1 - _bevel, _bevel)
  ..close();
final _tileFaceShaders = <PuzzlePalette, List<ui.Shader>>{};
final _tileFacePaint = Paint();
final _tileEdgePaint = Paint();
final _tileOutlinePaint = Paint()..style = PaintingStyle.stroke;
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
  canvas.save();
  canvas.translate(r.left, r.top);
  canvas.scale(r.width, r.height);
  const unit = Rect.fromLTWH(0, 0, 1, 1);
  const radius = Radius.circular(.065);
  final shape = RRect.fromRectAndRadius(unit, radius);
  canvas.drawRRect(
    shape.shift(const Offset(0, .055)),
    _tileEdgePaint..color = palette.tileDark(color).withValues(alpha: opacity),
  );
  final shaders = _tileFaceShaders.putIfAbsent(
    palette,
    () => List.generate(
      palette.colors.length,
      (i) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(palette.colors[i], Colors.white, .08)!,
          palette.colors[i],
          Color.lerp(palette.colors[i], Colors.black, .08)!,
        ],
        stops: const [0, .52, 1],
      ).createShader(unit),
    ),
  );
  canvas.clipRRect(shape);
  canvas.drawRRect(
    shape,
    _tileFacePaint
      ..shader = shaders[color]
      ..color = Colors.white.withValues(alpha: opacity),
  );
  for (final edge in [
    (_topBevel, palette.tileLight(color)),
    (_leftBevel, palette.tileLeft(color)),
    (_bottomBevel, palette.tileDark(color)),
    (_rightBevel, palette.tileRight(color)),
  ]) {
    canvas.drawPath(
      edge.$1,
      _tileEdgePaint..color = edge.$2.withValues(alpha: opacity),
    );
  }
  canvas.drawRRect(
    RRect.fromRectAndRadius(unit.deflate(_bevel), const Radius.circular(.025)),
    _tileOutlinePaint
      ..color = palette.tileLight(color).withValues(alpha: .22 * opacity)
      ..strokeWidth = .01,
  );
  canvas.drawRRect(
    shape.deflate(.006),
    _tileOutlinePaint
      ..color = palette.tileLight(color).withValues(alpha: .27 * opacity)
      ..strokeWidth = .012,
  );
  canvas.restore();
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
    final reward = rewardForMove(move) ?? RewardKind.good;
    final caption = move.state.combo > 1
        ? 'COMBO ×${move.state.combo}${move.allClear ? ' · ALL CLEAR' : ''}'
        : move.lines > 1
        ? '${move.lines} LINES CLEARED'
        : 'CLEAN MOVE';
    return switch (reward) {
      RewardKind.good => RewardStyle(
        'GOOD!',
        caption,
        const Color(0xFFE6FFF7),
        const Color(0xFF48E3AC),
        32,
        900,
      ),
      RewardKind.great => RewardStyle(
        'GREAT!',
        caption,
        const Color(0xFFE4FAFF),
        const Color(0xFF51CFFF),
        34,
        980,
      ),
      RewardKind.combo => RewardStyle(
        'COMBO ×${move.state.combo}',
        'KEEP IT GOING',
        const Color(0xFFF5F0FF),
        const Color(0xFFB693FF),
        34,
        1040,
      ),
      RewardKind.amazing => RewardStyle(
        'AMAZING!',
        caption,
        const Color(0xFFFFF6C5),
        const Color(0xFFFFC54D),
        37,
        1140,
      ),
      RewardKind.incredible => RewardStyle(
        'INCREDIBLE!',
        caption,
        const Color(0xFFFFEEF9),
        const Color(0xFFFF75B6),
        33,
        1240,
      ),
      RewardKind.newBest => const RewardStyle(
        'NEW BEST!',
        'PERSONAL RECORD',
        Color(0xFFFFF4BE),
        Color(0xFFFFB844),
        35,
        1400,
      ),
    };
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
  _RewardText? _rewardText;
  late final ClearFeedback _hover = ghost == null
      ? const ClearFeedback()
      : ClearFeedback.preview(board, ghost!, ghostX, ghostY);
  late final ClearFeedback _clear = move == null
      ? const ClearFeedback()
      : ClearFeedback.forMove(move!);
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
    if (refinedFrame && palette.id == 'ocean') {
      canvas.drawRRect(
        bg.deflate(.5),
        Paint()
          ..color = palette.line.withValues(alpha: .38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    final effect = move;
    final clearing =
        effect != null &&
        effect.lines > 0 &&
        elapsed < (reduceMotion ? 100 : 420);
    final visible = clearing ? effect.beforeClear : board;
    for (var i = 0; i < 64; i++) {
      final x = 8.0 + i % 8 * 38, y = 8.0 + i ~/ 8 * 38;
      final rect = Rect.fromLTWH(x, y, 34, 34);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(refinedFrame ? 3 : 4)),
        Paint()..color = palette.cell,
      );
      // Only the rendered clear projection changes colour; stored cells retain
      // their original material until the engine removes the completed lines.
      final originalColor = visible[i];
      final color = !_hover.isEmpty
          ? _hover.colorAt(i, originalColor)
          : clearing
          ? _clear.colorAt(i, originalColor)
          : originalColor;
      if (color < 0) continue;
      var opacity = 1.0, scale = 1.0;
      if (!reduceMotion && effect != null) {
        if (clearing && effect.cleared.contains(i)) {
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
    if (!_hover.isEmpty) _lineGlow(canvas, _hover, .75);
    if (ghost case final piece?) {
      for (final c in piece.cells) {
        final rect = Rect.fromLTWH(
          8 + (ghostX + c.x) * 38.0,
          8 + (ghostY + c.y) * 38.0,
          34,
          34,
        );
        final inClear = _hover.cells.contains(
          (ghostY + c.y) * 8 + ghostX + c.x,
        );
        paintTile(
          canvas,
          rect,
          piece.color,
          opacity: inClear ? .92 : .32,
          palette: palette,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(.5), const Radius.circular(4)),
          Paint()
            ..color = palette.accent.withValues(alpha: .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
    if (effect != null) {
      if (effect.lines > 0 && !reduceMotion) _clearFx(canvas, effect);
      if (rewardForMove(effect) != null) _reward(canvas, effect);
    }
    canvas.restore();
  }

  void _lineGlow(Canvas canvas, ClearFeedback feedback, double opacity) {
    final color = feedback.color;
    if (color == null) return;
    final hue = palette.colors[color], light = palette.tileLight(color);
    for (final rect in [
      for (final row in feedback.rows)
        Rect.fromLTWH(7, 7 + row * 38.0, 306, 36),
      for (final column in feedback.columns)
        Rect.fromLTWH(7 + column * 38.0, 7, 36, 306),
    ]) {
      final shape = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(
        shape,
        Paint()
          ..color = hue.withValues(alpha: .18 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7,
      );
      canvas.drawRRect(
        shape,
        Paint()
          ..color = light.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _rewardSparks(
    Canvas canvas,
    double ms,
    RewardStyle cfg,
    PuzzleMove effect,
  ) {
    const rainbow = [
      Color(0xFF59E7FF),
      Color(0xFFFF78C8),
      Color(0xFFFFD66B),
      Color(0xFF8CFFBD),
      Color(0xFFB99AFF),
      Color(0xFFFFA06B),
    ];
    final kind = rewardForMove(effect);
    final count = kind == RewardKind.good ? 18 : 28;
    const center = Offset(160, 58);
    final line = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final t = (ms - (i % 4) * 18) / 680;
      if (t < 0 || t >= 1) continue;
      final alpha = _clamp(t * 10) * math.pow(1 - t, .8).toDouble();
      final angle = i * math.pi * 2 / count + .13;
      final direction = Offset(math.cos(angle), math.sin(angle) * .42);
      final radius = 46 + _ease(t) * (88 + (i % 3) * 7);
      final length = (26 + (i % 5) * 6) * (1 - t * .65);
      final head = center + direction * radius;
      final tail = center + direction * (radius - length);
      final hue = rainbow[i % rainbow.length];
      final color = palette.light ? Color.lerp(hue, Colors.black, .20)! : hue;
      canvas.drawLine(
        tail,
        head,
        line
          ..shader = null
          ..strokeWidth = 4.5 + (i % 3) * .5
          ..color = color.withValues(alpha: alpha * .12),
      );
      canvas.drawLine(
        tail,
        head,
        line
          ..color = Colors.white
          ..strokeWidth = 1.5 + (i % 3) * .4
          ..shader = ui.Gradient.linear(
            tail,
            head,
            [
              color.withValues(alpha: 0),
              color.withValues(alpha: alpha),
              Colors.white.withValues(alpha: alpha * .9),
            ],
            const [0, .72, 1],
          ),
      );
      if (i % 3 == 0) {
        _spark(
          canvas,
          head,
          2.1 + (i % 4) * .45,
          hue.withValues(alpha: alpha),
          angle + t,
        );
      }
    }
    final t = _clamp(ms / 440);
    if (t < 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: 64 + 170 * _ease(t),
          height: 18 + 46 * _ease(t),
        ),
        Paint()
          ..color = cfg.light.withValues(alpha: (1 - t) * .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _clearFx(Canvas canvas, PuzzleMove effect) {
    final reward = RewardStyle.forMove(effect);
    final color = _clear.color ?? 0;
    final light = palette.tileLight(color);
    if (elapsed < 340) _lineGlow(canvas, _clear, (1 - elapsed / 340) * .85);
    if (elapsed < 420) {
      final x = -50 + _clamp(elapsed / 340) * 430;
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            light.withValues(alpha: .85),
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
        final color = i % 3 == 0 ? reward.light : light;
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
    final cfg = RewardStyle.forMove(effect), ms = elapsed - 120;
    if (ms < 0 || ms >= cfg.duration) return;
    final fade = _clamp(ms / 65) * _clamp((cfg.duration - ms) / 180);
    final enter = _clamp(ms / 240),
        exit = _clamp((ms - cfg.duration + 180) / 180);
    final lettering = _rewardText ??= _buildRewardText(cfg, effect);
    canvas.saveLayer(
      const Rect.fromLTWH(0, 0, 320, 180),
      Paint()..color = Colors.white.withValues(alpha: fade),
    );
    canvas.drawRect(
      const Rect.fromLTWH(20, 0, 280, 180),
      Paint()
        ..shader = RadialGradient(
          colors: [
            cfg.dark.withValues(alpha: .19),
            cfg.dark.withValues(alpha: 0),
          ],
        ).createShader(const Rect.fromLTWH(35, -45, 250, 250)),
    );
    if (!reduceMotion) _rewardSparks(canvas, ms, cfg, effect);
    canvas.translate(
      160,
      reduceMotion ? 66 : 66 + 9 * (1 - _ease(enter)) - 16 * _ease(exit),
    );
    final scale = reduceMotion ? 1.0 : .64 + .36 * _back(enter);
    canvas.scale(scale);
    canvas.rotate(reduceMotion ? 0 : -.018 * (1 - _ease(enter)));
    canvas.save();
    canvas.scale(lettering.fit);
    canvas.translate(-lettering.fill.width / 2, -lettering.fill.height);
    lettering.stroke.paint(canvas, const Offset(0, 2));
    lettering.fill.paint(canvas, Offset.zero);
    canvas.restore();
    final underline =
        lettering.fill.width *
        lettering.fit *
        (reduceMotion ? 1 : _ease(enter));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-underline / 2, 4, underline, 1.6),
        const Radius.circular(.8),
      ),
      Paint()
        ..shader =
            LinearGradient(
              colors: [
                cfg.dark.withValues(alpha: 0),
                cfg.light,
                cfg.dark.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromLTWH(-underline / 2, 4, math.max(1, underline), 1.6),
            ),
    );
    lettering.caption.paint(canvas, Offset(-lettering.caption.width / 2, 11));
    canvas.restore();

    // The bonus leaves the clear location separately from the title.
    final t = _clamp((elapsed - 260) / 620);
    if (t > 0 && t < 1 && effect.cleared.isNotEmpty) {
      var center = Offset.zero;
      for (final cell in effect.cleared) {
        center += Offset(25 + cell % 8 * 38.0, 25 + cell ~/ 8 * 38.0);
      }
      center /= effect.cleared.length.toDouble();
      final travel = reduceMotion ? 0.0 : t * t;
      final position = Offset.lerp(center, const Offset(32, -8), travel)!;
      canvas.saveLayer(
        const Rect.fromLTWH(0, 0, 320, 320),
        Paint()
          ..color = Colors.white.withValues(
            alpha: _clamp(t * 8) * math.pow(1 - t, 1.4).toDouble(),
          ),
      );
      lettering.points.paint(
        canvas,
        position - Offset(lettering.points.width / 2, lettering.points.height),
      );
      canvas.restore();
    }
  }

  _RewardText _buildRewardText(RewardStyle cfg, PuzzleMove effect) {
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
    final stroke = _text(
      cfg.title,
      style.copyWith(
        foreground: Paint()
          ..color = (palette.light ? palette.ink : palette.end).withValues(
            alpha: .95,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeJoin = StrokeJoin.round,
      ),
    );
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
    final caption = _text(
      cfg.caption,
      TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: palette.ink,
        height: 1,
      ),
    );
    final points = _text(
      '+${effect.points}',
      TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: palette.light ? palette.ink : cfg.light,
        height: 1,
      ),
    );
    return _RewardText(stroke, fill, caption, points, fit);
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

class _RewardText {
  const _RewardText(
    this.stroke,
    this.fill,
    this.caption,
    this.points,
    this.fit,
  );
  final TextPainter stroke, fill, caption, points;
  final double fit;
}
