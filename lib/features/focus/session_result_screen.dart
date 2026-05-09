import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class SessionResultScreen extends StatefulWidget {
  const SessionResultScreen({super.key});

  @override
  State<SessionResultScreen> createState() => _SessionResultScreenState();
}

class _SessionResultScreenState extends State<SessionResultScreen> {
  bool _unlockDialogShown = false;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        if (!_unlockDialogShown) {
          final unlocked = store.consumeUnlockedPets();
          if (unlocked.isNotEmpty) {
            _unlockDialogShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(store.t('focus.petUnlocked')),
                  content: Text(
                    store.t('focus.petUnlockedBody', {
                      'pet': unlocked.first.name,
                    }),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(store.t('common.done')),
                    ),
                  ],
                ),
              );
            });
          }
        }
        final result = store.lastResult;
        final goal = store.todayGoalProgress;
        return ScreenScaffold(
          title: store.t('focus.resultTitle'),
          children: [
            CatudyPanel(
              color: CatudyColors.lavenderSoft,
              accentColor: CatudyColors.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: CatudyColors.teal.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: CatudyColors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result == null
                              ? store.t('focus.resultEmpty')
                              : store.t('focus.resultComplete'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: CatudyColors.blueFor(context),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result == null
                        ? store.t('focus.resultEmptyBody')
                        : store.t('focus.resultSaved', {
                            'category': store.categoryName(result.categoryId),
                            'minutes': result.minutes,
                          }),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      height: 1.45,
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      store.t('focus.resultSummary'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ResultMetricTile(
                          icon: Icons.add_circle_rounded,
                          label: store.t('focus.resultPointsEarned'),
                          value: '+${result.gold} ${store.t('common.points')}',
                          color: CatudyColors.violet,
                        ),
                        _ResultMetricTile(
                          icon: Icons.pets_rounded,
                          label: store.t('focus.resultPetEffect'),
                          value: store.t('focus.resultPetEffectValue', {
                            'pet': store.petName,
                          }),
                          color: CatudyColors.teal,
                        ),
                        _ResultMetricTile(
                          icon: Icons.local_fire_department_rounded,
                          label: store.t('focus.resultStreak'),
                          value: store.t('focus.resultStreakValue', {
                            'days': store.streakDays,
                          }),
                          color: CatudyColors.coral,
                        ),
                        _ResultMetricTile(
                          icon: Icons.track_changes_rounded,
                          label: store.t('focus.resultGoal'),
                          value:
                              '${goal.completedMinutes}/${goal.goalMinutes}${store.t('common.minutesShort')}',
                          color: CatudyColors.tealDark,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.t('achievements.title'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final achievement in store.achievements.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            achievement.unlocked
                                ? Icons.verified_rounded
                                : achievement.icon,
                            color: achievement.unlocked
                                ? CatudyColors.teal
                                : CatudyColors.violet,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              achievement.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${achievement.progress.clamp(0, achievement.target)}/${achievement.target}',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => context.go('/focus/category'),
              icon: const Icon(Icons.replay_rounded),
              label: Text(store.t('focus.focusAgain')),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/stats'),
                    icon: const Icon(Icons.query_stats_rounded),
                    label: Text(store.t('focus.seeStats')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/pet-room'),
                    icon: const Icon(Icons.pets_rounded),
                    label: Text(store.t('profile.petRoom')),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ResultMetricTile extends StatelessWidget {
  const _ResultMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
