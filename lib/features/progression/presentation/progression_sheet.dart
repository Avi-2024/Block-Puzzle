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
    barrierColor: Colors.black.withValues(alpha: .66),
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
            maxHeight: MediaQuery.sizeOf(context).height * .84,
          ),
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF123B88),
                AppTheme.gameBoard,
                AppTheme.gameBoardDeep,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x99020A1C),
                blurRadius: 34,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 13, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 46,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .24),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'REWARDS',
                              style: TextStyle(
                                color: AppTheme.gameText,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Coins, themes and achievements',
                              style: TextStyle(
                                color: AppTheme.gameTextMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFF8A3D),
            Color(0xFFB75CFF),
            Color(0xFF385BFF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x66385BFF),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${controller.dailyStreak} DAY STREAK',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                    Text(
                      available
                          ? 'Day ${controller.nextDailyStreak} reward is ready.'
                          : 'Come back tomorrow to keep the streak alive.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .84),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3C2DB8),
                disabledBackgroundColor: Colors.white.withValues(alpha: .30),
                disabledForegroundColor: Colors.white.withValues(alpha: .80),
                padding: const EdgeInsets.symmetric(vertical: 14),
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
        color: Colors.white.withValues(alpha: selected ? .10 : .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? AppTheme.success
              : Colors.white.withValues(alpha: .10),
        ),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: AppTheme.success.withValues(alpha: .14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
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
                  style: const TextStyle(
                    color: AppTheme.gameTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: selected ? AppTheme.success : AppTheme.primary,
              foregroundColor:
                  selected ? const Color(0xFF062419) : AppTheme.gameText,
              disabledBackgroundColor: Colors.white.withValues(alpha: .12),
              disabledForegroundColor: Colors.white.withValues(alpha: .46),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
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
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(theme.board),
            Color(theme.backgroundBottom),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
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
              borderRadius: BorderRadius.circular(3),
              boxShadow: index.isEven
                  ? <BoxShadow>[
                      BoxShadow(
                        color: color.withValues(alpha: .28),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
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
        color: Colors.white.withValues(alpha: unlocked ? .085 : .05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? AppTheme.success.withValues(alpha: .34)
              : Colors.white.withValues(alpha: .07),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppTheme.success.withValues(alpha: .18)
                  : Colors.white.withValues(alpha: .07),
              shape: BoxShape.circle,
              border: Border.all(
                color: unlocked
                    ? AppTheme.success.withValues(alpha: .30)
                    : Colors.white.withValues(alpha: .06),
              ),
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    color: AppTheme.gameTextMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
    return Row(
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.gameTextMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.white.withValues(alpha: .18),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
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
        gradient: LinearGradient(
          colors: <Color>[
            const Color(0xFFFFD447).withValues(alpha: .24),
            const Color(0xFFFFA33D).withValues(alpha: .15),
          ],
        ),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: const Color(0xFFFFD447).withValues(alpha: .24),
        ),
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
