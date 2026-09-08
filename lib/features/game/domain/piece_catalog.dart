import 'cell_offset.dart';

class PieceShape {
  const PieceShape(
    this.id,
    this.cells, {
    this.weight = 1,
    this.minMoves = 0,
  });

  final String id;
  final List<CellOffset> cells;
  final int weight;
  final int minMoves;
}

abstract final class PieceCatalog {
  static const List<PieceShape> shapes = <PieceShape>[
    // Small / forgiving shapes.
    PieceShape('single', <CellOffset>[CellOffset(0, 0)], weight: 5),
    PieceShape(
      'h2',
      <CellOffset>[CellOffset(0, 0), CellOffset(0, 1)],
      weight: 6,
    ),
    PieceShape(
      'v2',
      <CellOffset>[CellOffset(0, 0), CellOffset(1, 0)],
      weight: 6,
    ),
    PieceShape(
      'h3',
      <CellOffset>[CellOffset(0, 0), CellOffset(0, 1), CellOffset(0, 2)],
      weight: 7,
    ),
    PieceShape(
      'v3',
      <CellOffset>[CellOffset(0, 0), CellOffset(1, 0), CellOffset(2, 0)],
      weight: 7,
    ),
    PieceShape(
      'square2',
      <CellOffset>[
        CellOffset(0, 0),
        CellOffset(0, 1),
        CellOffset(1, 0),
        CellOffset(1, 1),
      ],
      weight: 6,
    ),

    // Four 3-cell corner orientations.
    PieceShape(
      'corner3_tl',
      <CellOffset>[CellOffset(0, 0), CellOffset(0, 1), CellOffset(1, 0)],
      weight: 5,
    ),
    PieceShape(
      'corner3_tr',
      <CellOffset>[CellOffset(0, 0), CellOffset(0, 1), CellOffset(1, 1)],
      weight: 5,
    ),
    PieceShape(
      'corner3_bl',
      <CellOffset>[CellOffset(0, 0), CellOffset(1, 0), CellOffset(1, 1)],
      weight: 5,
    ),
    PieceShape(
      'corner3_br',
      <CellOffset>[CellOffset(0, 1), CellOffset(1, 0), CellOffset(1, 1)],
      weight: 5,
    ),

    // Medium shapes enter after the player has had a few moves.
    PieceShape(
      'h4',
      <CellOffset>[
        CellOffset(0, 0),
        CellOffset(0, 1),
        CellOffset(0, 2),
        CellOffset(0, 3),
      ],
      weight: 5,
      minMoves: 6,
    ),
    PieceShape(
      'v4',
      <CellOffset>[
        CellOffset(0, 0),
        CellOffset(1, 0),
        CellOffset(2, 0),
        CellOffset(3, 0),
      ],
      weight: 5,
      minMoves: 6,
    ),
    PieceShape(
      't4_up',
      <CellOffset>[
        CellOffset(0, 0),
        CellOffset(0, 1),
        CellOffset(0, 2),
        CellOffset(1, 1),
      ],
      weight: 4,
      minMoves: 8,
    ),
    PieceShape(
      't4_down',
      <CellOffset>[
        CellOffset(0, 1),
        CellOffset(1, 0),
        CellOffset(1, 1),
        CellOffset(1, 2),
      ],
      weight: 4,
      minMoves: 8,
    ),
    PieceShape(
      't4_left',
      <CellOffset>[
        CellOffset(0, 0),
        CellOffset(1, 0),
        CellOffset(1, 1),
        CellOffset(2, 0),
      ],
      weight: 4,
      minMoves: 8,
    ),
    PieceShape(
      't4_right',
      <CellOffset>[
        CellOffset(0, 1),
        CellOffset(1, 0),
        CellOffset(1, 1),
        CellOffset(2, 1),
      ],
      weight: 4,
      minMoves: 8,
    ),

    // 5-cell L shapes. These create real planning pressure later in a run.
    PieceShape(
      'l5_tl',
      <CellOffset>[
        CellOffset(0, 0),
        CellOffset(1, 0),
        CellOffset(2, 0),
        CellOffset(2, 1),
        CellOffset(2, 2),
      ],
      weight: 3,
      minMoves: 16,
    ),
    PieceShape(
      'l5_tr',
      <CellOffset>[
        CellOffset(0, 2),
        CellOffset(1, 2),
        CellOffset(2, 0),
        CellOffset(2, 1),
        CellOffset(2, 2),
      ],
      weight: 3,
      minMoves: 16,
    ),
    PieceShape(
      'l5_bl',
      <CellOffset>[
        CellOffset(0, 0),
        CellOffset(0, 1),
        CellOffset(0, 2),
        CellOffset(1, 0),
        CellOffset(2, 0),
      ],
      weight: 3,
      minMoves: 16,
    ),
    PieceShape(
      'l5_br',
      <CellOffset>[
        CellOffset(0, 0),
        CellOffset(0, 1),
        CellOffset(0, 2),
        CellOffset(1, 2),
        CellOffset(2, 2),
      ],
      weight: 3,
      minMoves: 16,
    ),

    // Long / large late-run pieces.
    PieceShape(
      'h5',
      <CellOffset>[
        CellOffset(0, 0),
        CellOffset(0, 1),
        CellOffset(0, 2),
        CellOffset(0, 3),
        CellOffset(0, 4),
      ],
      weight: 3,
      minMoves: 20,
    ),
    PieceShape(
      'v5',
      <CellOffset>[
        CellOffset(0, 0),
        CellOffset(1, 0),
        CellOffset(2, 0),
        CellOffset(3, 0),
        CellOffset(4, 0),
      ],
      weight: 3,
      minMoves: 20,
    ),
    PieceShape(
      'square3',
      <CellOffset>[
        CellOffset(0, 0),
        CellOffset(0, 1),
        CellOffset(0, 2),
        CellOffset(1, 0),
        CellOffset(1, 1),
        CellOffset(1, 2),
        CellOffset(2, 0),
        CellOffset(2, 1),
        CellOffset(2, 2),
      ],
      weight: 2,
      minMoves: 26,
    ),
  ];

  static List<PieceShape> eligibleForMoves(int movesPlayed) => shapes
      .where((PieceShape shape) => shape.minMoves <= movesPlayed)
      .toList(growable: false);
}
