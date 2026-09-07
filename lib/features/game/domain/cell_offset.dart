class CellOffset {
  const CellOffset(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellOffset && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}
