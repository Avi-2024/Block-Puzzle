import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One icon family across the game HUD, progression and outcome surfaces.
/// The 500 stroke keeps controls readable at 22 px; compact rewards use 600.
abstract final class GameIcons {
  static const IconData back = LucideIcons.arrowLeft500;
  static const IconData settings = LucideIcons.settings2500;
  static const IconData restart = LucideIcons.rotateCcw500;
  static const IconData trophy = LucideIcons.trophy600;
  static const IconData target = LucideIcons.flag600;
  static const IconData coin = LucideIcons.coins600;
  static const IconData calendar = LucideIcons.calendarDays500;
  static const IconData calendarDone = LucideIcons.calendarCheck500;
  static const IconData board = LucideIcons.grid2X2500;
  static const IconData play = LucideIcons.playCircle500;
  static const IconData medal = LucideIcons.medal600;
  static const IconData fire = LucideIcons.flame600;
  static const IconData gift = LucideIcons.gift500;
  static const IconData check = LucideIcons.check600;
  static const IconData lock = LucideIcons.lock500;
  static const IconData privacy = LucideIcons.shieldCheck500;
}
