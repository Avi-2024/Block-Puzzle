import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../daily_challenge/domain/daily_challenge_definition.dart';
import '../../game/presentation/game_canvas_v2_shell.dart';
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

  void _openDailyChallenge() {
    final DailyChallengeDefinition challenge =
        DailyChallengeDefinition.forDate(DateTime.now());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameCanvasV2Shell(
          child: UnifiedGameScreen.daily(challenge: challenge),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_runtime.initialized) {
      return const ColoredBox(
        color: AppTheme.gameBackgroundBottom,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              color: AppTheme.gameText,
              strokeWidth: 2.6,
            ),
          ),
        ),
      );
    }

    final GameThemeDefinition theme = _runtime.controller.selectedTheme;
    final DailyChallengeDefinition challenge =
        DailyChallengeDefinition.forDate(DateTime.now());
    final bool challengeDone = _runtime.controller
        .isDailyChallengeCompleted(challenge.dayKey);
    final Widget themedGame = theme.id == 'classic'
        ? widget.child
        : ColorFiltered(
            colorFilter: ColorFilter.mode(
              Color(theme.backgroundTop),
              BlendMode.hue,
            ),
            child: widget.child,
          );
    final double top = MediaQuery.paddingOf(context).top + 58;

    return Stack(
      children: <Widget>[
        themedGame,
        Positioned(
          left: 14,
          top: top,
          child: _FloatingActionPill(
            onTap: () => showProgressionSheet(context, _runtime.controller),
            icon: Icons.monetization_on_rounded,
            iconColor: AppTheme.warning,
            label: '${_runtime.controller.coins}',
            trailingIcon: _runtime.controller.dailyRewardAvailable
                ? Icons.card_giftcard_rounded
                : null,
            trailingColor: AppTheme.success,
          ),
        ),
        Positioned(
          right: 14,
          top: top,
          child: _FloatingActionPill(
            onTap: _openDailyChallenge,
            icon: challengeDone
                ? Icons.check_circle_rounded
                : Icons.calendar_today_rounded,
            iconColor: challengeDone
                ? const Color(0xFF062419)
                : AppTheme.warning,
            label: challengeDone ? 'DAILY ✓' : 'DAILY',
            labelColor: challengeDone
                ? const Color(0xFF062419)
                : AppTheme.gameText,
            backgroundColor: challengeDone
                ? AppTheme.success.withValues(alpha: .90)
                : AppTheme.gameBoard.withValues(alpha: .74),
          ),
        ),
      ],
    );
  }
}

class _FloatingActionPill extends StatelessWidget {
  const _FloatingActionPill({
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor = AppTheme.gameText,
    this.backgroundColor,
    this.trailingIcon,
    this.trailingColor,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final Color? backgroundColor;
  final IconData? trailingIcon;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppTheme.gameBoard.withValues(alpha: .74),
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
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .15,
                ),
              ),
              if (trailingIcon != null) ...<Widget>[
                const SizedBox(width: 6),
                Icon(
                  trailingIcon,
                  color: trailingColor ?? AppTheme.success,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
