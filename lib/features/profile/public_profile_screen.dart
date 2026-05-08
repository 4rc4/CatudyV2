import 'package:flutter/material.dart';

import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final visited = store.visitedProfile;
        final name = visited?.name ?? store.displayName;
        final points = visited?.points ?? store.focusPoints;
        final weekMinutes = visited?.totalMinutes ?? store.weeklyMinutes;
        final streak = visited?.streakDays ?? store.streakDays;
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
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          store.t('profile.thisWeek', {'minutes': weekMinutes}),
                        ),
                      ),
                      Chip(label: Text('$points ${store.t('common.points')}')),
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
              ),
            ),
          ],
        );
      },
    );
  }
}
