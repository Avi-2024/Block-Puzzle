class GameThemeDefinition {
  const GameThemeDefinition({
    required this.id,
    required this.name,
    required this.unlockCost,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.board,
    required this.cell,
    required this.cellEdge,
    required this.palette,
  });

  final String id;
  final String name;
  final int unlockCost;
  final int backgroundTop;
  final int backgroundBottom;
  final int board;
  final int cell;
  final int cellEdge;
  final List<int> palette;
}

abstract final class GameThemeCatalog {
  static const GameThemeDefinition classic = GameThemeDefinition(
    id: 'classic',
    name: 'Classic Blue',
    unlockCost: 0,
    backgroundTop: 0xFF173A78,
    backgroundBottom: 0xFF0C244F,
    board: 0xFF112D5C,
    cell: 0xFF244575,
    cellEdge: 0xFF315686,
    palette: <int>[
      0xFF2F9CFF,
      0xFF27D4F2,
      0xFF42D879,
      0xFFFFD447,
      0xFFFF9F3F,
      0xFFFF5E68,
      0xFF9B6BFF,
    ],
  );

  static const GameThemeDefinition sunset = GameThemeDefinition(
    id: 'sunset',
    name: 'Sunset Pop',
    unlockCost: 450,
    backgroundTop: 0xFF6B2E63,
    backgroundBottom: 0xFF321B4F,
    board: 0xFF4A2557,
    cell: 0xFF6A3B68,
    cellEdge: 0xFF805078,
    palette: <int>[
      0xFFFF6B6B,
      0xFFFF9F43,
      0xFFFFD93D,
      0xFF48DBFB,
      0xFF1DD1A1,
      0xFF5F27CD,
      0xFFC56CF0,
    ],
  );

  static const GameThemeDefinition mint = GameThemeDefinition(
    id: 'mint',
    name: 'Mint Rush',
    unlockCost: 800,
    backgroundTop: 0xFF0A5A57,
    backgroundBottom: 0xFF063C43,
    board: 0xFF0B4C50,
    cell: 0xFF1C6D70,
    cellEdge: 0xFF2A7E81,
    palette: <int>[
      0xFF4DABF7,
      0xFF3BC9DB,
      0xFF51CF66,
      0xFFFFD43B,
      0xFFFF922B,
      0xFFFF6B6B,
      0xFFB197FC,
    ],
  );

  static const List<GameThemeDefinition> all = <GameThemeDefinition>[
    classic,
    sunset,
    mint,
  ];

  static GameThemeDefinition byId(String id) => all.firstWhere(
        (GameThemeDefinition theme) => theme.id == id,
        orElse: () => classic,
      );
}
