import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final challenge = store.weeklySocialChallenge;
        final profiles = store.socialProfiles.take(5).toList();
        final friends = store.friendProfiles;
        return ScreenScaffold(
          title: store.t('social.title'),
          children: [
            CatudyPanel(
              color: CatudyColors.cream,
              accentColor: CatudyColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        color: CatudyColors.teal,
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          challenge.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: CatudyColors.blueFor(context),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    challenge.description,
                    style: TextStyle(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
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
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go('/lobby/create'),
                    icon: const Icon(Icons.add_home_rounded),
                    label: Text(store.t('home.createLobby')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.go('/lobby/join'),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(store.t('home.joinLobby')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.t('social.friends'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (friends.isEmpty)
                    Text(
                      store.t('social.noFriends'),
                      style: TextStyle(color: CatudyColors.mutedFor(context)),
                    )
                  else
                    for (var index = 0; index < friends.length; index++)
                      _SocialProfileRow(
                        rank: index + 1,
                        profile: friends[index],
                        store: store,
                        compact: true,
                      ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.t('social.focusBoard'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < profiles.length; index++)
                    _SocialProfileRow(
                      rank: index + 1,
                      profile: profiles[index],
                      store: store,
                      compact: false,
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

class _SocialProfileRow extends StatelessWidget {
  const _SocialProfileRow({
    required this.rank,
    required this.profile,
    required this.store,
    required this.compact,
  });

  final int rank;
  final LeaderboardProfile profile;
  final CatudyDemoStore store;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: profile.currentUser
            ? CatudyColors.lavenderSoft
            : CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              profile.currentUser
                  ? '${profile.name} (${store.t('leaderboard.you')})'
                  : profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CatudyColors.blueFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (!compact && !profile.currentUser) ...[
            IconButton(
              tooltip: store.friendUserIds.contains(profile.userId)
                  ? store.t('social.removeFriend')
                  : store.t('social.addFriend'),
              onPressed: () => store.toggleFriend(profile.userId),
              icon: Icon(
                store.friendUserIds.contains(profile.userId)
                    ? Icons.person_remove_rounded
                    : Icons.person_add_alt_1_rounded,
              ),
            ),
            IconButton(
              tooltip: store.t('social.visitProfile'),
              onPressed: () {
                store.visitProfile(profile.userId);
                context.go('/public-profile');
              },
              icon: const Icon(Icons.visibility_rounded),
            ),
          ] else ...[
            Text(
              '${profile.totalMinutes}${store.t('common.minutesShort')}',
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (!profile.currentUser)
              IconButton(
                tooltip: store.t('social.visitProfile'),
                onPressed: () {
                  store.visitProfile(profile.userId);
                  context.go('/public-profile');
                },
                icon: const Icon(Icons.visibility_rounded),
              ),
          ],
        ],
      ),
    );
  }
}
