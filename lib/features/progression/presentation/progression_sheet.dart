import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../application/progression_controller.dart';
import '../domain/achievement_definition.dart';
import '../domain/game_theme_definition.dart';

Future<void> showProgressionSheet(
  BuildContext context,
  ProgressionController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (BuildContext context) => _ProgressionSheet(controller: controller),
  );
}

class _ProgressionSheet extends StatelessWidget {
  const _ProgressionSheet({required this.controller});

  final ProgressionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .82,
          ),
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: BoxDecoration(
            color: AppTheme.gameBoard,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: .10)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'REWARDS',
                        style: TextStyle(
                          color: AppTheme.gameText,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    _CoinPill(value: controller.coins),
                  ],
                ),
                const SizedBox(height: 16),
                _DailyRewardCard(controller: controller),
                const SizedBox(height: 22),
                const _SectionTitle('THEMES'),
                const SizedBox(height: 10),
                ...GameThemeCatalog.all.map(
                  (GameThemeDefinition theme) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ThemeCard(controller: controller, theme: theme),
                  ),
                ),
                const SizedBox(height: 12),
                const _SectionTitle('ACHIEVEMENTS'),
                const SizedBox(height: 10),
                ...AchievementCatalog.all.map(
                  (AchievementDefinition achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AchievementRow(
                      achievement: achievement,
                      unlocked:
                          controller.isAchievementUnlocked(achievement.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({required this.controller});

  final ProgressionController controller;

  @override
  Widget build(BuildContext context) {
    final bool available = controller.dailyRewardAvailable;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF5F43D8), Color(0xFF8759F2)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFFFD447)),
              const SizedBox(width: 7),
              Text(
                '${controller.dailyStreak} DAY STREAK',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            available
                ? 'Day ${controller.nextDailyStreak} reward is ready.'
                : 'Come back tomorrow to keep the streak alive.',
            style: TextStyle(color: Colors.white.withValues(alpha: .82)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4D34BE),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: available
                  ? () => controller.claimDailyReward()
                  : null,
              icon: Icon(
                available ? Icons.card_giftcard_rounded : Icons.check_rounded,
              ),
              label: Text(
                available
                    ? 'CLAIM +${controller.nextDailyReward} COINS'
                    : 'CLAIMED TODAY',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.controller, required this.theme});

  final ProgressionController controller;
  final GameThemeDefinition theme;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = controller.isThemeUnlocked(theme.id);
    final bool selected = controller.state.selectedThemeId == theme.id;
    final bool canAfford = unlocked || controller.coins >= theme.unlockCost;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppTheme.success
              : Colors.white.withValues(alpha: .09),
        ),
      ),
      child: Row(
        children: <Widget>[
          _ThemePreview(theme: theme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  theme.name,
                  style: const TextStyle(
                    color: AppTheme.gameText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  selected
                      ? 'Active theme'
                      : unlocked
                          ? 'Unlocked'
                          : '${theme.unlockCost} coins',
                  style: const TextStyle(color: AppTheme.gameTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: selected || !canAfford
                ? null
                : () => controller.unlockAndSelectTheme(theme.id),
            child: Text(
              selected
                  ? 'ON'
                  : unlocked
                      ? 'USE'
                      : 'UNLOCK',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});

  final GameThemeDefinition theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Color(theme.board),
        borderRadius: BorderRadius.circular(14),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: 9,
        itemBuilder: (BuildContext context, int index) {
          final Color color = index.isEven
              ? Color(theme.palette[index % theme.palette.length])
              : Color(theme.cell);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        },
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.achievement,
    required this.unlocked,
  });

  final AchievementDefinition achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppTheme.success.withValues(alpha: .18)
                  : Colors.white.withValues(alpha: .07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? Icons.check_rounded : Icons.lock_outline_rounded,
              color: unlocked ? AppTheme.success : AppTheme.gameTextMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: AppTheme.gameText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: AppTheme.gameTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CoinPill(value: achievement.rewardCoins, compact: true),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.gameTextMuted,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.value, this.compact = false});

  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0x33FFD447),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.monetization_on_rounded,
            color: AppTheme.warning,
            size: compact ? 14 : 17,
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              color: AppTheme.gameText,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
