import 'package:flutter/material.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({this.userId, super.key});

  final String? userId;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        if (userId != null) {
          store.ensurePublicProfile(userId!);
        }
        final requestedProfile = userId == null
            ? null
            : store.profileByUserId(userId!);
        final visited = userId == null
            ? store.visitedProfile
            : requestedProfile;
        final currentUserId = store.authUserId ?? store.publicUserCode;
        final isCurrentUser =
            userId == null ||
            userId == currentUserId ||
            userId == store.publicUserCode;
        final name =
            visited?.name ?? (isCurrentUser ? store.displayName : userId!);
        final totalMinutes =
            visited?.totalMinutes ??
            (isCurrentUser ? store.totalFocusMinutes : 0);
        final streak =
            visited?.streakDays ?? (isCurrentUser ? store.streakDays : 0);
        final sessions = visited?.sessionsCount ?? store.sessionsCount;
        final favorite =
            visited?.favoriteCategory ??
            (isCurrentUser ? store.favoriteCategory.name : '');
        final statsVisible = visited == null && !isCurrentUser
            ? false
            : visited?.statsPublic ?? store.publicStatsVisible;
        return ScreenScaffold(
          title: store.t('profile.publicTitle'),
          showBack: true,
          fallbackBackPath: visited == null ? '/profile' : '/social',
          children: [
            CatudyPanel(
              color: CatudyColors.lavenderSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: CatudyColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    store.t('profile.publicBody'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CatudyColors.muted,
                      height: 1.45,
                    ),
                  ),
                  if (statsVisible) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            store.t('profile.totalPublic', {
                              'minutes': totalMinutes,
                            }),
                          ),
                        ),
                        Chip(
                          label: Text('$streak${store.t('common.daysShort')}'),
                        ),
                        if (visited == null)
                          Chip(
                            label: Text(
                              store.t('profile.favorite', {
                                'category': store.favoriteCategory.name,
                              }),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (statsVisible)
              CatudyPanel(
                accentColor: CatudyColors.teal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.t('profile.publicStatsTitle'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PublicStatsGrid(
                      store: store,
                      totalMinutes: totalMinutes,
                      streak: streak,
                      sessions: sessions,
                      favorite: favorite,
                    ),
                  ],
                ),
              )
            else
              CatudyPanel(
                accentColor: CatudyColors.coral,
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: CatudyColors.coral),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        store.t('profile.publicStatsHidden'),
                        style: TextStyle(
                          color: CatudyColors.mutedFor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

class _PublicStatsGrid extends StatelessWidget {
  const _PublicStatsGrid({
    required this.store,
    required this.totalMinutes,
    required this.streak,
    required this.sessions,
    required this.favorite,
  });

  final CatudyDemoStore store;
  final int totalMinutes;
  final int streak;
  final int sessions;
  final String favorite;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _PublicStatTile(
          icon: Icons.hourglass_bottom_rounded,
          label: store.t('profile.totalPublic', {'minutes': totalMinutes}),
        ),
        _PublicStatTile(
          icon: Icons.local_fire_department_rounded,
          label: '$streak${store.t('common.daysShort')}',
        ),
        _PublicStatTile(
          icon: Icons.track_changes_rounded,
          label: store.t('profile.sessionsPublic', {'count': sessions}),
        ),
        if (favorite.isNotEmpty)
          _PublicStatTile(
            icon: Icons.menu_book_rounded,
            label: store.t('profile.favorite', {'category': favorite}),
          ),
      ],
    );
  }
}

class _PublicStatTile extends StatelessWidget {
  const _PublicStatTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CatudyColors.teal.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: CatudyColors.teal),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
