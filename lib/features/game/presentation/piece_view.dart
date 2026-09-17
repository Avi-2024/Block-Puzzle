import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/block_piece.dart';

class PieceView extends StatelessWidget {
  const PieceView({
    required this.piece,
    required this.cellSize,
    this.elevated = false,
    super.key,
  });

  final BlockPiece piece;
  final double cellSize;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: piece.width * cellSize,
      height: piece.height * cellSize,
      child: Stack(
        children: piece.cells
            .map((cell) {
              return Positioned(
                left: cell.col * cellSize,
                top: cell.row * cellSize,
                width: cellSize,
                height: cellSize,
                child: PuzzleTile(
                  paletteIndex: piece.paletteIndex,
                  elevated: elevated,
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

/// Shared by settled cells, tray pieces and the lifted drag piece.
class PuzzleTile extends StatelessWidget {
  const PuzzleTile({required this.paletteIndex, this.elevated = false, this.highlighted = false, super.key});
  final int paletteIndex;
  final bool highlighted;
  final bool elevated;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(1.5),
    decoration: BoxDecoration(
      gradient: AppTheme.pieceGradient(paletteIndex),
      border: highlighted ? Border.all(color: const Color(0xFFFFE8A3), width: 1.5) : null,
      borderRadius: BorderRadius.circular(3),
      boxShadow: elevated ? const <BoxShadow>[
        BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 4)),
      ] : null,
    ),
    child: const ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(3)),
      child: CustomPaint(painter: _TileBevel()),
    ),
  );
}

class _TileBevel extends CustomPainter {
  const _TileBevel();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double edge = size.shortestSide * .12;
    canvas.drawPath(Path()
      ..moveTo(0, 0)..lineTo(w, 0)..lineTo(w-edge, edge)
      ..lineTo(edge, edge)..lineTo(edge, h-edge)..lineTo(0, h)..close(),
      Paint()..color = const Color(0x55FFFFFF));
    canvas.drawPath(Path()
      ..moveTo(w, 0)..lineTo(w, h)..lineTo(0, h)
      ..lineTo(edge, h-edge)..lineTo(w-edge, h-edge)
      ..lineTo(w-edge, edge)..close(),
      Paint()..color = const Color(0x33000000));
  }

  @override
  bool shouldRepaint(_TileBevel oldDelegate) => false;
}
