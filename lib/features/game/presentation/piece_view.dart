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
    final Color color = AppTheme
        .piecePalette[piece.paletteIndex % AppTheme.piecePalette.length];
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
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: AppTheme.pieceGradient(piece.paletteIndex),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .20),
                      width: .8,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: elevated ? .42 : .20),
                        blurRadius: elevated ? 12 : 5,
                        offset: Offset(0, elevated ? 7 : 3),
                      ),
                    ],
                  ),
                  child: const TileGloss(),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class TileGloss extends StatelessWidget {
  const TileGloss({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Align(
          alignment: const Alignment(0, -.82),
          child: FractionallySizedBox(
            widthFactor: .70,
            heightFactor: .12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .34),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: .82,
            heightFactor: .11,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
