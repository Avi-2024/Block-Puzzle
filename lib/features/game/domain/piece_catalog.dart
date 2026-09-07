import 'cell_offset.dart';

class PieceShape {
  const PieceShape(this.id, this.cells);

  final String id;
  final List<CellOffset> cells;
}

abstract final class PieceCatalog {
  static const List<PieceShape> shapes = <PieceShape>[
    PieceShape('single', <CellOffset>[CellOffset(0, 0)]),
    PieceShape('h2', <CellOffset>[CellOffset(0, 0), CellOffset(0, 1)]),
    PieceShape('h3', <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(0, 2),
    ]),
    PieceShape('v2', <CellOffset>[CellOffset(0, 0), CellOffset(1, 0)]),
    PieceShape('v3', <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(2, 0),
    ]),
    PieceShape('square2', <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(1, 0),
      CellOffset(1, 1),
    ]),
    PieceShape('l3_a', <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(1, 1),
    ]),
    PieceShape('l3_b', <CellOffset>[
      CellOffset(0, 1),
      CellOffset(1, 0),
      CellOffset(1, 1),
    ]),
    PieceShape('t4', <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(0, 2),
      CellOffset(1, 1),
    ]),
    PieceShape('l4', <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(2, 0),
      CellOffset(2, 1),
    ]),
    PieceShape('corner4', <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(1, 0),
      CellOffset(2, 0),
    ]),
    PieceShape('h4', <CellOffset>[
      CellOffset(0, 0),
      CellOffset(0, 1),
      CellOffset(0, 2),
      CellOffset(0, 3),
    ]),
    PieceShape('v4', <CellOffset>[
      CellOffset(0, 0),
      CellOffset(1, 0),
      CellOffset(2, 0),
      CellOffset(3, 0),
    ]),
  ];
}
