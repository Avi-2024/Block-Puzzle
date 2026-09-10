import 'package:flutter/material.dart';

import '../core/ads/monetization_bootstrap.dart';
import '../core/theme/app_theme.dart';
import '../features/game/presentation/unified_game_screen.dart';
import '../features/progression/presentation/progression_bootstrap.dart';

class BlockivaApp extends StatelessWidget {
  const BlockivaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blockiva',
      theme: AppTheme.bright,
      home: const ProgressionBootstrap(
        child: MonetizationBootstrap(
          child: UnifiedGameScreen.endless(),
        ),
      ),
    );
  }
}
