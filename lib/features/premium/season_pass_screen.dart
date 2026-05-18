import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/premium/catudy_premium_models.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/catudy_visual_system.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class SeasonPassScreen extends StatelessWidget {
  const SeasonPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final season = store.currentSeason;
        final progress = store.seasonProgress;
        final target = season.targetMinutes == 0 ? 1 : season.targetMinutes;
        final ratio = (progress.focusMinutes / target).clamp(0.0, 1.0);
        final daysLeft = season.endsAt
            .difference(DateTime.now())
            .inDays
            .clamp(0, 999);

        return ScreenScaffold(
          title: store.t('season.focusPassTitle'),
          showBack: true,
          fallbackBackPath: '/plus',
          children: [
            CatudyStagePanel(
              eyebrow: season.name,
              title: store.t('season.heroTitle'),
              subtitle: season.description,
              icon: Icons.beach_access_rounded,
              art: const CatudyMascotBadge(
                size: 104,
                accent: CatudyColors.teal,
              ),
              progress: ratio,
              progressLabel: store.t('season.xpProgress', {
                'xp': progress.focusMinutes,
                'target': target,
              }),
              footer: Row(
                children: [
                  Expanded(
                    child: CatudyMetricTile(
                      icon: Icons.schedule_rounded,
                      label: store.t('season.daysLeft'),
                      value: '$daysLeft',
                      color: CatudyColors.teal,
                      dense: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CatudyMetricTile(
                      icon: Icons.workspace_premium_rounded,
                      label: store.t('season.status'),
                      value: store.hasPremiumAccess
                          ? store.t('premium.statusActive')
                          : store.t('premium.statusInactive'),
                      color: CatudyColors.yellow,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _UpgradeStrip(store: store),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CatudySectionHeader(
                          title: store.t('season.freeTrack'),
                          icon: Icons.card_giftcard_rounded,
                          accentColor: CatudyColors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CatudySectionHeader(
                          title: store.t('season.premiumTrack'),
                          icon: Icons.workspace_premium_rounded,
                          accentColor: CatudyColors.violet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CatudyRewardRail(
                    currentValue: progress.focusMinutes,
                    freeItems: [
                      for (final reward in season.freeTrack.rewards)
                        _railItem(context, store, reward),
                    ],
                    premiumItems: [
                      for (final reward in season.premiumTrack.rewards)
                        _railItem(context, store, reward),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DailyQuestPanel(store: store),
          ],
        );
      },
    );
  }

  CatudyRewardRailItem _railItem(
    BuildContext context,
    CatudyDemoStore store,
    SeasonReward reward,
  ) {
    final claimed = store.seasonProgress.claimedRewardIds.contains(reward.id);
    final unlocked =
        store.seasonProgress.focusMinutes >= reward.thresholdMinutes;
    final premiumBlocked = reward.premiumOnly && !store.hasPremiumAccess;
    return CatudyRewardRailItem(
      title: reward.title,
      subtitle: store.t('season.unlockAtXp', {'xp': reward.thresholdMinutes}),
      icon: _rewardIcon(reward.kind),
      color: reward.premiumOnly ? CatudyColors.violet : CatudyColors.teal,
      threshold: reward.thresholdMinutes,
      claimed: claimed,
      unlocked: unlocked,
      locked: premiumBlocked,
      actionLabel: store.t('season.claim'),
      onClaim: claimed || !unlocked || premiumBlocked
          ? null
          : () => store.claimSeasonReward(reward.id),
    );
  }

  IconData _rewardIcon(SeasonRewardKind kind) => switch (kind) {
    SeasonRewardKind.gold => Icons.monetization_on_rounded,
    SeasonRewardKind.crate => Icons.inventory_2_rounded,
    SeasonRewardKind.cosmetic => Icons.auto_awesome_rounded,
  };
}

class _UpgradeStrip extends StatelessWidget {
  const _UpgradeStrip({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    if (store.hasPremiumAccess) {
      return CatudyPanel(
        color: CatudyColors.cream,
        accentColor: CatudyColors.teal,
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: CatudyColors.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                store.t('season.premiumActiveBody'),
                style: TextStyle(
                  color: CatudyColors.blueFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return CatudyStagePanel(
      title: store.t('season.upgradeTitle'),
      subtitle: store.t('season.upgradeBody'),
      icon: Icons.workspace_premium_rounded,
      accentColor: CatudyColors.violet,
      secondaryColor: CatudyColors.teal,
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/plus'),
          icon: const Icon(Icons.workspace_premium_rounded),
          label: Text(store.t('season.upgradeCta')),
        ),
      ],
    );
  }
}

class _DailyQuestPanel extends StatelessWidget {
  const _DailyQuestPanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final goal = store.todayGoalProgress;
    final todayReminders = store.todosForDay(DateTime.now());
    final completedReminders = todayReminders.where((todo) => todo.done).length;
    return CatudyPanel(
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: store.t('season.dailyQuests'),
            subtitle: store.t('season.dailyQuestsBody'),
            icon: Icons.event_note_rounded,
            accentColor: CatudyColors.teal,
          ),
          const SizedBox(height: 12),
          _QuestRow(
            icon: Icons.timer_rounded,
            title: store.t('season.questFocusTitle'),
            progress:
                '${goal.completedMinutes}/${goal.goalMinutes}${store.t('common.minutesShort')}',
            ratio: goal.ratio,
            reward: '+50 XP',
            color: CatudyColors.teal,
          ),
          const SizedBox(height: 10),
          _QuestRow(
            icon: Icons.task_alt_rounded,
            title: store.t('season.questReminderTitle'),
            progress: '$completedReminders/${todayReminders.length}',
            ratio: todayReminders.isEmpty
                ? 0
                : completedReminders / todayReminders.length,
            reward: '+25 XP',
            color: CatudyColors.violet,
          ),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.icon,
    required this.title,
    required this.progress,
    required this.ratio,
    required this.reward,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String progress;
  final double ratio;
  final String reward;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 8,
                    color: color,
                    backgroundColor: CatudyColors.surfaceStrongFor(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                progress,
                style: TextStyle(
                  color: CatudyColors.mutedFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Chip(label: Text(reward)),
            ],
          ),
        ],
      ),
    );
  }
}
