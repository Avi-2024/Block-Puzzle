import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../game/presentation/game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(flex: 2),
              const _BrandMark(),
              const SizedBox(height: 24),
              Text(
                'BLOCKIVA',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 48,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'PLACE  •  CLEAR  •  COMBO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  letterSpacing: 2,
                  color: Color(0xFF8EA0C5),
                ),
              ),
              const Spacer(flex: 3),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GameScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'PLAY NOW',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Offline puzzle • No login • Built for quick sessions',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF7381A2)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 94,
        height: 94,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppTheme.primary, AppTheme.accent],
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x558B5CF6),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: const Icon(Icons.grid_view_rounded, size: 54),
      ),
    );
  }
}
