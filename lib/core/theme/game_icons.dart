import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// One icon family across the game HUD, progression and outcome surfaces.
/// Filled rewards read at 16 px; bold controls remain clear at 22 px.
abstract final class GameIcons {
  static const IconData back = PhosphorIconsBold.arrowLeft;
  static const IconData settings = PhosphorIconsBold.gearSix;
  static const IconData restart = PhosphorIconsBold.arrowClockwise;
  static const IconData trophy = PhosphorIconsFill.trophy;
  static const IconData target = PhosphorIconsFill.flag;
  static const IconData coin = PhosphorIconsFill.coin;
  static const IconData calendar = PhosphorIconsBold.calendarBlank;
  static const IconData calendarDone = PhosphorIconsBold.calendarCheck;
  static const IconData board = PhosphorIconsBold.gridFour;
  static const IconData play = PhosphorIconsFill.playCircle;
  static const IconData medal = PhosphorIconsFill.medal;
  static const IconData fire = PhosphorIconsFill.fire;
  static const IconData gift = PhosphorIconsBold.gift;
  static const IconData check = PhosphorIconsBold.check;
  static const IconData lock = PhosphorIconsBold.lock;
  static const IconData privacy = PhosphorIconsBold.shieldCheck;
}
