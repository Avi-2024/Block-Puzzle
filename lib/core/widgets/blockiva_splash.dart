import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.view_module_rounded, color: AppTheme.accent, size: 64),
                  const SizedBox(height: 18),
                  const Text('BLOCKIVA', style: TextStyle(
                    color: AppTheme.gameText, fontSize: 30,
                    fontWeight: FontWeight.w900, letterSpacing: 4,
                  )),
                  const SizedBox(height: 32),
                  const SizedBox(width: 80, child: LinearProgressIndicator(
                    minHeight: 2, color: AppTheme.accent,
                    backgroundColor: AppTheme.gameBoard,
                    semanticsLabel: 'Preparing your game',
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
