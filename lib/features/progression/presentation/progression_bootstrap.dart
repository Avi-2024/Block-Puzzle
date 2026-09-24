import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/blockiva_splash.dart';
import '../../daily_challenge/domain/daily_challenge_definition.dart';
import '../../game/presentation/unified_game_screen.dart';
import '../application/progression_runtime.dart';
import '../domain/game_theme_definition.dart';
import 'progression_sheet.dart';

class ProgressionBootstrap extends StatefulWidget {
  const ProgressionBootstrap({required this.child, super.key});

  final Widget child;

  @override
  State<ProgressionBootstrap> createState() => _ProgressionBootstrapState();
}

class _ProgressionBootstrapState extends State<ProgressionBootstrap> {
  final ProgressionRuntime _runtime = ProgressionRuntime.instance;

  @override
  void initState() {
    super.initState();
    _runtime.addListener(_refresh);
    unawaited(_runtime.initialize());
  }

  @override
  void dispose() {
    _runtime.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_runtime.initialized) {
      return const BlockivaSplash();
    }

    final GameThemeDefinition theme = _runtime.controller.selectedTheme;
    final Widget themedGame = theme.id == 'classic'
        ? widget.child
        : ColorFiltered(
            colorFilter: ColorFilter.mode(
              Color(theme.backgroundTop),
              BlendMode.hue,
            ),
            child: widget.child,
          );
    return themedGame;
  }
}

/// Lives inside the game HUD, so loading and outcome screens cover it normally.
class ProgressionActions extends StatelessWidget {
  const ProgressionActions({required this.score, super.key});
  final Widget score;

  void _openDailyChallenge(BuildContext context) {
    final DailyChallengeDefinition challenge = DailyChallengeDefinition.forDate(
      DateTime.now(),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UnifiedGameScreen.daily(challenge: challenge),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final runtime = ProgressionRuntime.instance;
    return AnimatedBuilder(
      animation: runtime,
      builder: (context, _) {
        final challenge = DailyChallengeDefinition.forDate(DateTime.now());
        final done = runtime.controller.isDailyChallengeCompleted(challenge.dayKey);
        return Row(children: [
          Expanded(child: Align(alignment: Alignment.centerLeft, child: _FloatingActionPill(
            onTap: () => showProgressionSheet(context, runtime.controller),
            icon: Icons.monetization_on_rounded,
            iconColor: AppTheme.warning,
            label: '${runtime.controller.coins}',
          ))),
          score,
          Expanded(child: Align(alignment: Alignment.centerRight, child: _FloatingActionPill(
            onTap: () => _openDailyChallenge(context),
            icon: done ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
            iconColor: done ? AppTheme.success : AppTheme.warning,
            label: 'DAILY',
          ))),
        ]);
      },
    );
  }
}

class _FloatingActionPill extends StatelessWidget {
  const _FloatingActionPill({
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.gameBoard.withValues(alpha: .74),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: .16)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x66030A22),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: iconColor, size: 17),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.gameText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
