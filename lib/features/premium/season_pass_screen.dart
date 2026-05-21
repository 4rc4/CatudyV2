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
            _SeasonSummaryCard(
              store: store,
              season: season,
              ratio: ratio,
              target: target,
              daysLeft: daysLeft,
            ),
            const SizedBox(height: 14),
            _UpgradeStrip(store: store),
            const SizedBox(height: 14),
            _RewardPreviewCard(
              store: store,
              season: season,
              progress: progress,
            ),
            const SizedBox(height: 14),
            _DailyQuestPanel(store: store),
          ],
        );
      },
    );
  }
}

class SeasonRewardsScreen extends StatelessWidget {
  const SeasonRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final season = store.currentSeason;
        final progress = store.seasonProgress;
        return ScreenScaffold(
          title: store.t('season.rewardsTitle'),
          showBack: true,
          fallbackBackPath: '/season',
          children: [
            CatudyPanel(
              accentColor: CatudyColors.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TrackHeaders(store: store),
                  const SizedBox(height: 14),
                  CatudyRewardRail(
                    currentValue: progress.focusMinutes,
                    freeItems: [
                      for (final reward in season.freeTrack.rewards)
                        _seasonRailItem(store, reward, claimsEnabled: true),
                    ],
                    premiumItems: [
                      for (final reward in season.premiumTrack.rewards)
                        _seasonRailItem(store, reward, claimsEnabled: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SeasonSummaryCard extends StatelessWidget {
  const _SeasonSummaryCard({
    required this.store,
    required this.season,
    required this.ratio,
    required this.target,
    required this.daysLeft,
  });

  final CatudyDemoStore store;
  final Season season;
  final double ratio;
  final int target;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final progress = store.seasonProgress;
    return CatudyPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      accentColor: CatudyColors.teal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.t('season.focusXp'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  store.t('season.xpProgress', {
                    'xp': progress.focusMinutes,
                    'target': target,
                  }),
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  color: CatudyColors.teal,
                  backgroundColor: CatudyColors.surfaceFor(context),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: CatudyColors.teal,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$daysLeft ${store.t('season.daysShort')}',
                      style: TextStyle(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CatudyAssetSlot(
            size: 96,
            accentColor: CatudyColors.violet,
            child: Image.asset('assets/brand/catudy-mascot.png'),
          ),
        ],
      ),
    );
  }
}

class _RewardPreviewCard extends StatelessWidget {
  const _RewardPreviewCard({
    required this.store,
    required this.season,
    required this.progress,
  });

  final CatudyDemoStore store;
  final Season season;
  final SeasonProgress progress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/season/rewards'),
      borderRadius: BorderRadius.circular(28),
      child: CatudyPanel(
        accentColor: CatudyColors.violet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _TrackTabs(store: store)),
                const Icon(
                  Icons.fullscreen_rounded,
                  color: CatudyColors.violet,
                ),
              ],
            ),
            const SizedBox(height: 14),
            CatudyRewardRail(
              currentValue: progress.focusMinutes,
              freeItems: [
                for (final reward in season.freeTrack.rewards)
                  _seasonRailItem(store, reward, claimsEnabled: false),
              ],
              premiumItems: [
                for (final reward in season.premiumTrack.rewards)
                  _seasonRailItem(store, reward, claimsEnabled: false),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                store.t('season.tapRewards'),
                style: TextStyle(
                  color: CatudyColors.violet,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackHeaders extends StatelessWidget {
  const _TrackHeaders({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

CatudyRewardRailItem _seasonRailItem(
  CatudyDemoStore store,
  SeasonReward reward, {
  required bool claimsEnabled,
}) {
  final claimed = store.seasonProgress.claimedRewardIds.contains(reward.id);
  final unlocked = store.seasonProgress.focusMinutes >= reward.thresholdMinutes;
  final premiumBlocked = reward.premiumOnly && !store.hasPremiumAccess;
  return CatudyRewardRailItem(
    title: _seasonRewardTitle(store, reward),
    subtitle: store.t('season.unlockAtXp', {'xp': reward.thresholdMinutes}),
    icon: _rewardIcon(reward.kind),
    color: reward.premiumOnly ? CatudyColors.violet : CatudyColors.teal,
    threshold: reward.thresholdMinutes,
    claimed: claimed,
    unlocked: unlocked,
    locked: premiumBlocked,
    actionLabel: store.t('season.claim'),
    onClaim: !claimsEnabled || claimed || !unlocked || premiumBlocked
        ? null
        : () => store.claimSeasonReward(reward.id),
  );
}

class _TrackTabs extends StatelessWidget {
  const _TrackTabs({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TrackPill(
            icon: Icons.card_giftcard_rounded,
            label: store.t('season.freeTrack'),
            color: CatudyColors.teal,
            active: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TrackPill(
            icon: Icons.workspace_premium_rounded,
            label: store.t('season.premiumTrack'),
            color: CatudyColors.violet,
            active: true,
          ),
        ),
      ],
    );
  }
}

class _TrackPill extends StatelessWidget {
  const _TrackPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: 0.28)
            : CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: active
              ? color.withValues(alpha: 0.54)
              : CatudyColors.lineFor(context),
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: active ? color : CatudyColors.mutedFor(context),
            size: 18,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active
                    ? CatudyColors.blueFor(context)
                    : CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _seasonRewardTitle(CatudyDemoStore store, SeasonReward reward) {
  final key = 'season.reward.${reward.id}';
  final localized = store.t(key);
  return localized == key ? reward.title : localized;
}

IconData _rewardIcon(SeasonRewardKind kind) => switch (kind) {
  SeasonRewardKind.gold => Icons.savings_rounded,
  SeasonRewardKind.crate => Icons.inventory_2_rounded,
  SeasonRewardKind.cosmetic => Icons.auto_awesome_rounded,
};

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
          onPressed: () => context.push('/plus?from=profile'),
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
