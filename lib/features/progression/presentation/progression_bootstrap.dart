import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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

  void _openDailyChallenge() {
    final DailyChallengeDefinition challenge =
        DailyChallengeDefinition.forDate(DateTime.now());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UnifiedGameScreen.daily(challenge: challenge),
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

    return Stack(
      children: <Widget>[
        themedGame,
        Positioned(
          left: 14,
          top: MediaQuery.paddingOf(context).top + 58,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: () => showProgressionSheet(
                context,
                _runtime.controller,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.gameBoard.withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: AppTheme.warning,
                      size: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_runtime.controller.coins}',
                      style: const TextStyle(
                        color: AppTheme.gameText,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (_runtime.controller.dailyRewardAvailable) ...<Widget>[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.card_giftcard_rounded,
                        color: AppTheme.success,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 14,
          top: MediaQuery.paddingOf(context).top + 58,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: _openDailyChallenge,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: challengeDone
                      ? AppTheme.success.withValues(alpha: .86)
                      : AppTheme.gameBoard.withValues(alpha: .78),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      challengeDone
                          ? Icons.check_circle_rounded
                          : Icons.calendar_today_rounded,
                      color: challengeDone
                          ? const Color(0xFF062419)
                          : AppTheme.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      challengeDone ? 'DAILY ✓' : 'DAILY',
                      style: TextStyle(
                        color: challengeDone
                            ? const Color(0xFF062419)
                            : AppTheme.gameText,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
