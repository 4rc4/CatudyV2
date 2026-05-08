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
        return ScreenScaffold(
          title: store.t('focus.resultTitle'),
          children: [
            CatudyPanel(
              color: CatudyColors.lavenderSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result == null
                        ? store.t('focus.resultEmpty')
                        : store.t('focus.resultComplete'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: CatudyColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
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
                      color: CatudyColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Chip(
                        label: Text(
                          '+${result?.gold ?? 0} ${store.t('common.gold')}',
                        ),
                      ),
                      Chip(
                        label: Text('${store.gold} ${store.t('common.gold')}'),
                      ),
                      Chip(
                        label: Text(
                          '${store.focusPoints} ${store.t('common.points')}',
                        ),
                      ),
                    ],
                  ),
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
              onPressed: () => context.go('/stats'),
              icon: const Icon(Icons.query_stats_rounded),
              label: Text(store.t('focus.seeStats')),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.go('/shop'),
              icon: const Icon(Icons.storefront_rounded),
              label: Text(store.t('focus.openShop')),
            ),
          ],
        );
      },
    );
  }
}
