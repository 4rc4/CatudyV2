import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class DurationScreen extends StatelessWidget {
  const DurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('focus.durationTitle'),
        showBack: true,
        fallbackBackPath: '/focus/category',
        children: [
          CatudyPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.selectedCategory.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: store.selectedCategory.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  store.t('focus.durationInfo'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CatudyColors.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              for (final minutes in store.durations)
                _DurationCard(minutes: minutes),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                store.startFocus();
                context.go('/focus/timer');
              },
              icon: const Icon(Icons.timer_rounded),
              label: Text(store.t('focus.startTimer')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  const _DurationCard({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final selected = store.selectedDurationMinutes == minutes;
        return InkWell(
          onTap: () => store.selectDuration(minutes),
          borderRadius: BorderRadius.circular(8),
          child: CatudyPanel(
            color: selected ? CatudyColors.lavenderSoft : CatudyColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$minutes',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: CatudyColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  store.t('common.minutes'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: CatudyColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
