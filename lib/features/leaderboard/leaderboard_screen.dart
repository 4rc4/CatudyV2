import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/catudy_assets.dart';
import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

enum _LeaderboardAction { room, profile }

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('leaderboard.title'),
        showBack: true,
        fallbackBackPath: '/',
        children: const [LeaderboardContent()],
      ),
    );
  }
}

class LeaderboardContent extends StatelessWidget {
  const LeaderboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final profiles = store.leaderboardProfiles;
        final currentUserIndex = profiles.indexWhere(
          (profile) => profile.currentUser,
        );
        final currentUser = currentUserIndex == -1
            ? null
            : profiles[currentUserIndex];

        return Column(
          children: [
            CatudyPanel(
              accentColor: CatudyColors.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LeaderboardHeader(store: store),
                  const SizedBox(height: 14),
                  for (var index = 0; index < profiles.length; index++) ...[
                    _LeaderboardListRow(
                      rank: index + 1,
                      profile: profiles[index],
                      store: store,
                    ),
                    if (index != profiles.length - 1)
                      Divider(
                        height: 22,
                        color: CatudyColors.lineFor(
                          context,
                        ).withValues(alpha: 0.75),
                      ),
                  ],
                ],
              ),
            ),
            if (currentUser != null) ...[
              const SizedBox(height: 12),
              _CurrentUserStrip(
                rank: currentUserIndex + 1,
                profile: currentUser,
                store: store,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                store.t('leaderboard.focusTimeRanking'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: CatudyColors.blueFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: CatudyColors.lavenderSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                store.t('leaderboard.overall'),
                style: const TextStyle(
                  color: CatudyColors.violet,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: CatudyColors.teal,
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                store.t('leaderboard.realMinutesOnly'),
                style: TextStyle(
                  color: CatudyColors.mutedFor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LeaderboardListRow extends StatelessWidget {
  const _LeaderboardListRow({
    required this.rank,
    required this.profile,
    required this.store,
  });

  final int rank;
  final LeaderboardProfile profile;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final pet = store.unlockablePets.firstWhere(
      (item) => item.id == profile.petId,
      orElse: () => store.unlockablePets.first,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: profile.currentUser
            ? CatudyColors.lavenderSoft.withValues(alpha: 0.76)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(width: 34, child: _RankMark(rank: rank)),
          const SizedBox(width: 8),
          _PetBadge(accent: pet.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CatudyColors.blueFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (profile.currentUser) ...[
                  const SizedBox(width: 6),
                  Text(
                    store.t('leaderboard.you'),
                    style: const TextStyle(
                      color: CatudyColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${profile.totalMinutes}${store.t('common.minutesShort')}',
            style: TextStyle(
              color: CatudyColors.coral,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (!profile.currentUser) ...[
            const SizedBox(width: 4),
            PopupMenuButton<_LeaderboardAction>(
              tooltip: store.t('social.moreActions'),
              onSelected: (action) {
                switch (action) {
                  case _LeaderboardAction.room:
                    store.visitPetRoom(profile.userId);
                    context.go('/pet-room');
                  case _LeaderboardAction.profile:
                    store.visitProfile(profile.userId);
                    context.go('/public-profile');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _LeaderboardAction.room,
                  child: Text(store.t('social.visitPetRoom')),
                ),
                PopupMenuItem(
                  value: _LeaderboardAction.profile,
                  child: Text(store.t('social.visitProfile')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrentUserStrip extends StatelessWidget {
  const _CurrentUserStrip({
    required this.rank,
    required this.profile,
    required this.store,
  });

  final int rank;
  final LeaderboardProfile profile;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final pet = store.unlockablePets.firstWhere(
      (item) => item.id == profile.petId,
      orElse: () => store.unlockablePets.first,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CatudyColors.coral,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          _PetBadge(accent: pet.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '${profile.totalMinutes}${store.t('common.minutesShort')}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankMark extends StatelessWidget {
  const _RankMark({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      final color = switch (rank) {
        1 => CatudyColors.yellow,
        2 => CatudyColors.blue,
        _ => CatudyColors.coral,
      };
      return Icon(Icons.emoji_events_rounded, color: color, size: 22);
    }
    return Text(
      '$rank',
      style: TextStyle(
        color: CatudyColors.mutedFor(context),
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _PetBadge extends StatelessWidget {
  const _PetBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: Image.asset(CatudyAssets.mascot, fit: BoxFit.contain),
    );
  }
}
