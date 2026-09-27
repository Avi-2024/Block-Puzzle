import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One icon family across the game HUD, progression and outcome surfaces.
/// Consistent 400/500 strokes give controls and rewards a quieter silhouette.
abstract final class GameIcons {
  static const IconData back = LucideIcons.arrowLeft500;
  static const IconData settings = LucideIcons.settings500;
  static const IconData restart = LucideIcons.rotateCcw400;
  static const IconData trophy = LucideIcons.trophy500;
  static const IconData target = LucideIcons.flag500;
  static const IconData coin = LucideIcons.coins500;
  static const IconData calendar = LucideIcons.calendarDays400;
  static const IconData calendarDone = LucideIcons.calendarCheck400;
  static const IconData board = LucideIcons.grid2X2500;
  static const IconData play = LucideIcons.playCircle500;
  static const IconData medal = LucideIcons.medal600;
  static const IconData fire = LucideIcons.flame600;
  static const IconData gift = LucideIcons.gift500;
  static const IconData check = LucideIcons.check600;
  static const IconData lock = LucideIcons.lock500;
  static const IconData privacy = LucideIcons.shieldCheck500;
}
