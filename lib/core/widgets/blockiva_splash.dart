import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'blockiva_mark.dart';

/// Visible only while real local initialization is pending; no minimum delay.
class BlockivaSplash extends StatelessWidget {
  const BlockivaSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: AppTheme.gameBackgroundBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.gameBackgroundTop, AppTheme.gameBackgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: reducedMotion ? 1 : .94, end: 1),
              duration: Duration(milliseconds: reducedMotion ? 0 : 240),
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BlockivaMark(size: 84),
                  SizedBox(height: 18),
                  Text(
                    'BLOCKIVA',
                    style: TextStyle(
                      color: AppTheme.gameText,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Small moves. Brilliant moments.',
                    style: TextStyle(
                      color: AppTheme.gameTextMuted,
                      fontSize: 13,
                      letterSpacing: .3,
                    ),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: 80,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: AppTheme.rewardCyan,
                      backgroundColor: AppTheme.gameBoard,
                      semanticsLabel: 'Preparing your game',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
