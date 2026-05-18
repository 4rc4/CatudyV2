import 'package:flutter/material.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/premium/catudy_premium_models.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class SeasonPassScreen extends StatelessWidget {
  const SeasonPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('season.title'),
        showBack: true,
        fallbackBackPath: '/plus',
        children: [
          CatudyPanel(
            color: CatudyColors.cream,
            accentColor: CatudyColors.teal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CatudySectionHeader(
                  title: store.currentSeason.name,
                  subtitle: store.currentSeason.description,
                  icon: Icons.emoji_events_rounded,
                  accentColor: CatudyColors.teal,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: store.currentSeason.targetMinutes == 0
                      ? 0
                      : (store.seasonProgress.focusMinutes /
                                store.currentSeason.targetMinutes)
                            .clamp(0, 1),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 8),
                Text(
                  store.t('season.progress', {
                    'minutes': store.seasonProgress.focusMinutes,
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _TrackPanel(
            title: store.t('season.freeTrack'),
            rewards: store.currentSeason.freeTrack.rewards,
            store: store,
          ),
          const SizedBox(height: 14),
          _TrackPanel(
            title: store.t('season.premiumTrack'),
            rewards: store.currentSeason.premiumTrack.rewards,
            store: store,
            premium: true,
          ),
        ],
      ),
    );
  }
}

class _TrackPanel extends StatelessWidget {
  const _TrackPanel({
    required this.title,
    required this.rewards,
    required this.store,
    this.premium = false,
  });

  final String title;
  final List<SeasonReward> rewards;
  final CatudyDemoStore store;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      accentColor: premium ? CatudyColors.violet : CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: title,
            icon: premium
                ? Icons.workspace_premium_rounded
                : Icons.card_giftcard_rounded,
            accentColor: premium ? CatudyColors.violet : CatudyColors.teal,
            trailing: premium && !store.hasPremiumAccess
                ? const Icon(Icons.lock_rounded, color: CatudyColors.violet)
                : null,
          ),
          const SizedBox(height: 10),
          for (final reward in rewards)
            _RewardRow(reward: reward, store: store),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.reward, required this.store});

  final SeasonReward reward;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final claimed = store.seasonProgress.claimedRewardIds.contains(reward.id);
    final unlocked =
        store.seasonProgress.focusMinutes >= reward.thresholdMinutes;
    final claimButton = FilledButton(
      onPressed:
          claimed ||
              !unlocked ||
              (reward.premiumOnly && !store.hasPremiumAccess)
          ? null
          : () => store.claimSeasonReward(reward.id),
      child: Text(
        claimed ? store.t('season.claimed') : store.t('season.claim'),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    (reward.premiumOnly
                            ? CatudyColors.violet
                            : CatudyColors.teal)
                        .withValues(alpha: 0.14),
                child: Icon(
                  reward.kind == SeasonRewardKind.crate
                      ? Icons.inventory_2_rounded
                      : reward.kind == SeasonRewardKind.cosmetic
                      ? Icons.auto_awesome_rounded
                      : Icons.monetization_on_rounded,
                  color: reward.premiumOnly
                      ? CatudyColors.violet
                      : CatudyColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      store.t('season.unlockAt', {
                        'minutes': reward.thresholdMinutes,
                      }),
                      style: TextStyle(color: CatudyColors.mutedFor(context)),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [content, const SizedBox(height: 10), claimButton],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 10),
              claimButton,
            ],
          );
        },
      ),
    );
  }
}
