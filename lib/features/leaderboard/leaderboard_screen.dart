import 'package:flutter/material.dart';

import '../../app/catudy_assets.dart';
import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final profiles = store.leaderboardProfiles;
        return ScreenScaffold(
          title: store.t('leaderboard.title'),
          showBack: true,
          fallbackBackPath: '/',
          children: [
            CatudyPanel(
              color: CatudyColors.cream,
              accentColor: CatudyColors.teal,
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: CatudyColors.teal.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: CatudyColors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      store.t('leaderboard.body'),
                      style: TextStyle(
                        color: CatudyColors.mutedFor(context),
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < profiles.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LeaderboardRow(
                  rank: index + 1,
                  profile: profiles[index],
                  store: store,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
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
    return CatudyPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: profile.currentUser
          ? CatudyColors.lavenderSoft
          : CatudyColors.surfaceFor(context),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank == 1
                    ? CatudyColors.yellow
                    : CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _PetBadge(accent: pet.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
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
                    if (profile.currentUser)
                      Text(
                        store.t('leaderboard.you'),
                        style: const TextStyle(
                          color: CatudyColors.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  store.t('leaderboard.roomSoon'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${profile.points}',
                style: TextStyle(
                  color: CatudyColors.blueFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                store.t('common.points'),
                style: TextStyle(
                  color: CatudyColors.mutedFor(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: store.t('leaderboard.visitSoon'),
            onPressed: null,
            icon: const Icon(Icons.meeting_room_rounded),
          ),
        ],
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
      width: 46,
      height: 46,
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
