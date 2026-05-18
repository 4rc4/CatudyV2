import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/catudy_assets.dart';
import '../../app/demo/catudy_demo_store.dart';
import '../../app/notifications/catudy_notification_service.dart';
import '../../app/premium/catudy_premium_models.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_info_bubble.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/floating_mascot.dart';
import '../../shared/widgets/store_builder.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return StoreBuilder(
      builder: (context, store) {
        final basicRecommendation = store.focusRecommendation;
        final coachRecommendation = store.coachRecommendation;
        final recommendationCategory = store.categoryName(
          store.hasPremiumAccess
              ? coachRecommendation.categoryId
              : basicRecommendation.categoryId,
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Column(
            children: [
              _HomeHeader(store: store),
              const SizedBox(height: 12),
              _FocusHeroCard(
                store: store,
                basicRecommendation: basicRecommendation,
                coachRecommendation: coachRecommendation,
                category: recommendationCategory,
              ),
              const SizedBox(height: 14),
              _DailyGoalPanel(store: store),
              const SizedBox(height: 14),
              _PetCompanionCard(store: store),
              const SizedBox(height: 14),
              _SecondaryHomePanel(store: store),
              const SizedBox(height: 14),
              CatudyPanel(
                accentColor: CatudyColors.teal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.t('home.todayReminders'),
                      style: textTheme.titleLarge?.copyWith(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (store.todosForDay(DateTime.now()).isEmpty)
                      Text(
                        store.t('home.noTodayReminders'),
                        style: TextStyle(color: CatudyColors.mutedFor(context)),
                      )
                    else
                      for (final todo in store.todosForDay(DateTime.now()))
                        _HomeTodoTile(todo: todo),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: CatudyColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: CatudyColors.teal.withValues(alpha: 0.18),
            ),
          ),
          child: Image.asset(CatudyAssets.logo),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.t('home.greeting'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: CatudyColors.blueFor(context),
                  fontWeight: FontWeight.w900,
                  height: 1.02,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                store.petDisplayName,
                style: TextStyle(
                  color: CatudyColors.mutedFor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go('/plus'),
          tooltip: store.t('premium.title'),
          style: IconButton.styleFrom(
            backgroundColor: store.hasPremiumAccess
                ? CatudyColors.violet.withValues(alpha: 0.16)
                : CatudyColors.surfaceFor(context),
            foregroundColor: store.hasPremiumAccess
                ? CatudyColors.violet
                : CatudyColors.mutedFor(context),
          ),
          icon: Icon(
            store.hasPremiumAccess
                ? Icons.workspace_premium_rounded
                : Icons.workspace_premium_outlined,
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          onPressed: () => context.push('/settings'),
          tooltip: store.t('pet.settings'),
          icon: const Icon(Icons.settings_rounded),
        ),
      ],
    );
  }
}

class _FocusHeroCard extends StatelessWidget {
  const _FocusHeroCard({
    required this.store,
    required this.basicRecommendation,
    required this.coachRecommendation,
    required this.category,
  });

  final CatudyDemoStore store;
  final FocusRecommendation basicRecommendation;
  final CoachRecommendation coachRecommendation;
  final String category;

  @override
  Widget build(BuildContext context) {
    final premiumActive = store.hasPremiumAccess;
    final minutes = premiumActive
        ? coachRecommendation.minutes
        : basicRecommendation.minutes;
    final reason = premiumActive
        ? '${coachRecommendation.headline} ${coachRecommendation.reason}'
        : basicRecommendation.basedOnHistory
        ? store.t('home.focusSuggestionReason', {
            'sessions': basicRecommendation.sessionsConsidered,
          })
        : store.t('home.focusSuggestionStarter');

    return CatudyPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      color: CatudyColors.lavenderSoft,
      accentColor: CatudyColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.t('home.focusTime'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            store.t('home.focusSuggestion', {
              'minutes': minutes,
              'category': category,
            }),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
              height: 1.06,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CatudyColors.mutedFor(context),
              height: 1.32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _FocusLaunchButton(
            minutes: minutes,
            onPressed: () {
              final focusRoute = store.consumeFocusNavigationRoute();
              if (focusRoute != null) {
                context.go(focusRoute);
                return;
              }
              store.prepareRecommendedFocus();
              store.startFocus();
              context.go('/focus/timer');
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  store.prepareRecommendedFocus();
                  context.go('/focus/start');
                },
                icon: const Icon(Icons.tune_rounded),
                label: Text(store.t('home.adjustFocus')),
              ),
              if (!premiumActive)
                OutlinedButton.icon(
                  onPressed: () => context.go('/plus'),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(store.t('home.unlockCoach')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PetCompanionCard extends StatelessWidget {
  const _PetCompanionCard({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final nextPets =
        store.unlockablePets
            .where((pet) => !store.unlockedPetIds.contains(pet.id))
            .toList()
          ..sort((a, b) => a.requiredPoints.compareTo(b.requiredPoints));
    final nextPet = nextPets.isEmpty ? null : nextPets.first;
    final remainingPoints = nextPet == null
        ? 0
        : (nextPet.requiredPoints - store.focusPoints).clamp(0, 999999);

    return CatudyPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      color: CatudyColors.cream,
      accentColor: CatudyColors.teal,
      child: Column(
        children: [
          Row(
            children: [
              const FloatingMascot(width: 72, height: 72),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.t('home.petWhisperTitle', {
                        'pet': store.petDisplayName,
                      }),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CatudyColors.blueFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      nextPet == null
                          ? store.t('home.petAllUnlocked')
                          : store.t('home.petNextUnlock', {
                              'pet': nextPet.name,
                              'points': remainingPoints,
                            }),
                      style: TextStyle(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: () => context.go('/pet-room'),
                child: Text(store.t('home.petButton')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PetStatusChip(
                  icon: Icons.sentiment_satisfied_rounded,
                  label:
                      '${store.t('home.happiness')}: ${store.petMood > 70 ? store.t('home.good') : store.t('home.normal')}',
                  infoTitle: store.t('home.happiness'),
                  infoMessage: store.languageCode == 'en'
                      ? 'Mochi gets happier with focus sessions and favorite items. High happiness makes the room feel more lively.'
                      : 'Mochi odak seanslar? ve sevdi?i e?yalarla daha mutlu olur. Mutluluk y?ksekken oda daha canl? hissettirir.',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PetStatusChip(
                  icon: Icons.local_cafe_rounded,
                  label:
                      '${store.t('home.hunger')}: ${store.petHunger < 35 ? store.t('home.full') : store.t('home.hungry')}',
                  infoTitle: store.t('home.hunger'),
                  infoMessage: store.languageCode == 'en'
                      ? 'Hunger rises over time. Regular focus and care keep your pet balanced.'
                      : 'A?l?k zamanla y?kselir. D?zenli odak ve bak?m petin dengesini korur.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryHomePanel extends StatelessWidget {
  const _SecondaryHomePanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final unlockedAchievements = store.achievements
        .where((achievement) => achievement.unlocked)
        .length;
    return CatudyPanel(
      accentColor: CatudyColors.violet,
      child: Column(
        children: [
          _HomeLinkRow(
            icon: Icons.groups_rounded,
            title: store.t('community.title'),
            subtitle: store.t('home.communityShortcut'),
            onTap: () => context.go('/community?tab=friends'),
          ),
          const Divider(height: 20),
          _HomeLinkRow(
            icon: Icons.emoji_events_rounded,
            title: store.t('leaderboard.title'),
            subtitle: store.t('home.rankingShortcut'),
            onTap: () => context.go('/community?tab=ranking'),
          ),
          const Divider(height: 20),
          _HomeLinkRow(
            icon: Icons.workspace_premium_rounded,
            title: store.t('season.previewTitle'),
            subtitle: store.t('home.collectionShortcut', {
              'count': unlockedAchievements,
            }),
            onTap: () => context.go('/season'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/lobby/create'),
                  icon: const Icon(Icons.add_home_rounded),
                  label: Text(store.t('home.createLobby')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/lobby/join'),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(store.t('home.joinLobby')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeLinkRow extends StatelessWidget {
  const _HomeLinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: CatudyColors.violet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: CatudyColors.violet),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: CatudyColors.blueFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: CatudyColors.mutedFor(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalPanel extends StatelessWidget {
  const _DailyGoalPanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final progress = store.todayGoalProgress;
    return CatudyPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: CatudyColors.cream,
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.track_changes_rounded, color: CatudyColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  store.t('home.dailyGoal'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _editGoal(context),
                icon: const Icon(Icons.edit_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress.ratio,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: CatudyColors.surfaceFor(context),
            color: progress.completed ? CatudyColors.teal : CatudyColors.violet,
          ),
          const SizedBox(height: 8),
          Text(
            store.t('home.dailyGoalProgress', {
              'done': progress.completedMinutes,
              'goal': progress.goalMinutes,
              'left': progress.remainingMinutes,
            }),
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editGoal(BuildContext context) async {
    final controller = TextEditingController(text: '${store.dailyGoalMinutes}');
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(store.t('home.editDailyGoal')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: store.t('home.goalMinutes'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(store.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text)),
            child: Text(store.t('common.save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (minutes != null) {
      store.updateDailyGoal(minutes);
    }
  }
}

class _HomeTodoTile extends StatelessWidget {
  const _HomeTodoTile({required this.todo});

  final CalendarTodo todo;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Checkbox(
              value: todo.done,
              onChanged: (_) {
                store.toggleTodo(todo.id);
                final updated = store.todos.firstWhere(
                  (item) => item.id == todo.id,
                  orElse: () => todo,
                );
                if (updated.done) {
                  unawaited(
                    CatudyNotificationService.instance.cancelReminder(updated),
                  );
                } else {
                  unawaited(
                    CatudyNotificationService.instance.scheduleReminder(
                      updated,
                      languageCode: store.languageCode,
                    ),
                  );
                }
              },
            ),
            Expanded(
              child: Text(
                todo.title,
                style: TextStyle(
                  color: CatudyColors.blueFor(context),
                  fontWeight: FontWeight.w800,
                  decoration: todo.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(
              '${todo.hour.toString().padLeft(2, '0')}:${todo.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetStatusChip extends StatelessWidget {
  const _PetStatusChip({
    required this.icon,
    required this.label,
    required this.infoTitle,
    required this.infoMessage,
  });

  final IconData icon;
  final String label;
  final String infoTitle;
  final String infoMessage;

  @override
  Widget build(BuildContext context) {
    return CatudyInfoTap(
      title: infoTitle,
      message: infoMessage,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 132),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CatudyColors.teal, size: 18),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusLaunchButton extends StatefulWidget {
  const _FocusLaunchButton({required this.minutes, required this.onPressed});

  final int minutes;
  final VoidCallback onPressed;

  @override
  State<_FocusLaunchButton> createState() => _FocusLaunchButtonState();
}

class _FocusLaunchButtonState extends State<_FocusLaunchButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: catudyDemoStore.t('focus.start'),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          scale: _pressed ? 0.985 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CatudyColors.violet, CatudyColors.teal],
              ),
              boxShadow: [
                BoxShadow(
                  color: CatudyColors.violet.withValues(
                    alpha: _pressed ? 0.16 : 0.28,
                  ),
                  blurRadius: _pressed ? 8 : 24,
                  offset: Offset(0, _pressed ? 4 : 14),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: _pressed ? 0.10 : 0.34),
                  blurRadius: 3,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.42),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: CatudyColors.violet,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catudyDemoStore.t('focus.start'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.minutes}${catudyDemoStore.t('common.minutesShort')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
