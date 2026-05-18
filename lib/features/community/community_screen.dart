import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_visual_system.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../lobby/lobby_screen.dart';
import '../social/social_screen.dart';

enum CommunityTab { friends, ranking, lobbies }

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({required this.initialTab, super.key});

  final CommunityTab initialTab;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late CommunityTab _tab = widget.initialTab;

  @override
  void didUpdateWidget(covariant CommunityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tab = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final requestCount =
            store.incomingFriendRequests.length +
            store.outgoingFriendRequests.length;
        return ScreenScaffold(
          title: store.t('community.title'),
          showBack: true,
          fallbackBackPath: '/',
          children: [
            _CommunityOverview(store: store, requestCount: requestCount),
            const SizedBox(height: 14),
            CatudyVisualTabs<CommunityTab>(
              selected: _tab,
              onChanged: (tab) {
                setState(() => _tab = tab);
                context.go('/community?tab=${_tabCode(tab)}');
              },
              tabs: [
                CatudyVisualTab(
                  value: CommunityTab.friends,
                  label: store.t('community.friendsTab'),
                  icon: Icons.people_alt_rounded,
                ),
                CatudyVisualTab(
                  value: CommunityTab.ranking,
                  label: store.t('community.rankingTab'),
                  icon: Icons.emoji_events_rounded,
                ),
                CatudyVisualTab(
                  value: CommunityTab.lobbies,
                  label: store.t('community.lobbiesTab'),
                  icon: Icons.meeting_room_rounded,
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: switch (_tab) {
                CommunityTab.friends => const Column(
                  key: ValueKey('friends'),
                  children: [FriendsCommunitySection()],
                ),
                CommunityTab.ranking => const Column(
                  key: ValueKey('ranking'),
                  children: [LeaderboardContent()],
                ),
                CommunityTab.lobbies => const Column(
                  key: ValueKey('lobbies'),
                  children: [LobbiesCommunitySection()],
                ),
              },
            ),
          ],
        );
      },
    );
  }

  String _tabCode(CommunityTab tab) => switch (tab) {
    CommunityTab.friends => 'friends',
    CommunityTab.ranking => 'ranking',
    CommunityTab.lobbies => 'lobbies',
  };
}

class _CommunityOverview extends StatelessWidget {
  const _CommunityOverview({required this.store, required this.requestCount});

  final CatudyDemoStore store;
  final int requestCount;

  @override
  Widget build(BuildContext context) {
    final challenge = store.weeklySocialChallenge;
    return CatudyPanel(
      color: CatudyColors.cream,
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CatudyColors.teal.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: CatudyColors.teal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CatudyColors.blueFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.t('community.supportingBody'),
                      style: TextStyle(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: challenge.ratio,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: CatudyColors.surfaceFor(context),
            color: challenge.completed
                ? CatudyColors.teal
                : CatudyColors.violet,
          ),
          const SizedBox(height: 8),
          Text(
            store.t('social.challengeProgress', {
              'done': challenge.currentMinutes,
              'goal': challenge.targetMinutes,
              'left': challenge.remainingMinutes,
              'people': challenge.participants,
            }),
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (requestCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CatudyColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mark_email_unread_rounded,
                    color: CatudyColors.coral,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      store.t('community.pendingRequests', {
                        'count': requestCount,
                      }),
                      style: TextStyle(
                        color: CatudyColors.blueFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
