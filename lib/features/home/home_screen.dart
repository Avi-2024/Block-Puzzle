import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../game/presentation/game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFF9F9FE),
              Color(0xFFF0EEFF),
              Color(0xFFFFF7F4),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Align(
                  alignment: Alignment.centerRight,
                  child: _MiniBadge(),
                ),
                const Spacer(),
                const _BrandMark(),
                const SizedBox(height: 26),
                Text(
                  'BLOCKIVA',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 50,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PLACE  •  CLEAR  •  COMBO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const _FeatureStrip(),
                const Spacer(flex: 2),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x336C63FF),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 19),
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const GameScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 30),
                    label: const Text(
                      'PLAY NOW',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Relaxing offline puzzle • Quick sessions • No login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
        width: 116,
        height: 116,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x246C63FF),
              blurRadius: 34,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: const _LogoBlocks(),
      ),
    );
  }
}

class _LogoBlocks extends StatelessWidget {
  const _LogoBlocks();

  @override
  Widget build(BuildContext context) {
    const List<Color> colors = <Color>[
      Color(0xFF6C63FF),
      Color(0xFF4CA7FF),
      Color(0xFFFF7657),
      Color(0xFFFFC84B),
      Color(0xFF39CFA0),
      Color(0xFFE96BFF),
    ];
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemCount: colors.length,
      itemBuilder: (BuildContext context, int index) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.pieceGradient(index),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(child: _FeatureChip(icon: Icons.swipe_rounded, label: 'DRAG')),
        SizedBox(width: 9),
        Expanded(child: _FeatureChip(icon: Icons.auto_awesome_rounded, label: 'CLEAR')),
        SizedBox(width: 9),
        Expanded(child: _FeatureChip(icon: Icons.bolt_rounded, label: 'COMBO')),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E5F2)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: AppTheme.primary, size: 21),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E6F2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.offline_bolt_rounded, color: AppTheme.success, size: 18),
          SizedBox(width: 6),
          Text(
            'OFFLINE',
            style: TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
