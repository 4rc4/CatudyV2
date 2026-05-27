import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        return ScreenScaffold(
          title: store.t('community.title'),
          showBack: true,
          fallbackBackPath: '/',
          children: [
            CatudyVisualTabs<CommunityTab>(
              selected: _tab,
              onChanged: (tab) {
                setState(() => _tab = tab);
                final uri = GoRouterState.of(context).uri;
                final from = uri.queryParameters['from'];
                final suffix = from == null ? '' : '&from=$from';
                context.replace('/community?tab=${_tabCode(tab)}$suffix');
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
