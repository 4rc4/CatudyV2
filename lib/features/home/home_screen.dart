import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/catudy_assets.dart';
import '../../app/demo/catudy_demo_store.dart';
import '../../app/notifications/catudy_notification_service.dart';
import '../../app/premium/catudy_premium_models.dart';
import '../../app/theme/catudy_colors.dart';
import '../../features/onboarding/pet_intro_tour.dart';
import '../../shared/widgets/catudy_info_bubble.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_pressable.dart';
import '../../shared/widgets/catudy_visual_system.dart';
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
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.push('/plus?from=home'),
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
          onPressed: () => showPetIntroTour(context),
          tooltip: store.t('pet.showTour'),
          icon: const Icon(Icons.info_rounded),
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
  });

  final CatudyDemoStore store;
  final FocusRecommendation basicRecommendation;
  final CoachRecommendation coachRecommendation;

  @override
  Widget build(BuildContext context) {
    final premiumActive = store.hasPremiumAccess;
    final minutes = premiumActive
        ? coachRecommendation.minutes
        : basicRecommendation.minutes;

    return CatudyPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      color: CatudyColors.lavenderSoft,
      accentColor: CatudyColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: CatudyColors.violet.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: CatudyColors.violet.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: CatudyColors.violet,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  store.t('home.focusTime'),
                  style: const TextStyle(
                    color: CatudyColors.violet,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  store.t('home.heroStudyTitle', {'minutes': minutes}),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CatudyMascotBadge(size: 106, accent: CatudyColors.teal),
            ],
          ),
          const SizedBox(height: 16),
          _FocusLaunchButton(
            minutes: minutes,
            onPressed: () {
              final focusRoute = store.consumeFocusNavigationRoute();
              if (focusRoute != null) {
                context.go(focusRoute);
                return;
              }
              store.prepareRecommendedFocus();
              context.go('/focus/start');
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LobbyQuickButton(
                  icon: Icons.add_home_work_rounded,
                  label: store.t('home.createLobby'),
                  color: CatudyColors.violet,
                  onTap: () => context.push('/lobby/create'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LobbyQuickButton(
                  icon: Icons.login_rounded,
                  label: store.t('home.joinLobby'),
                  color: CatudyColors.tealDark,
                  onTap: () => context.push('/lobby/join'),
                ),
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
                  label: _moodLabel(store),
                  infoTitle: store.t('home.happiness'),
                  infoMessage: store.languageCode == 'en'
                      ? 'Mochi gets happier with focus sessions and favorite items. High happiness makes the room feel more lively.'
                      : 'Mochi gerçek odak serileriyle daha mutlu olur. Mutluluk yüksekken oda daha canlı hissettirir.',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PetStatusChip(
                  icon: Icons.local_cafe_rounded,
                  label: _hungerLabel(store),
                  infoTitle: store.t('home.hunger'),
                  infoMessage: store.languageCode == 'en'
                      ? 'Hunger rises over time. Regular focus and care keep your pet balanced.'
                      : 'Odak yapılmadığında açlık artar. Bugünkü gerçek seanslar dengeyi toparlar.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _moodLabel(CatudyDemoStore store) {
    if (store.petMood >= 72) {
      return store.t('home.happy');
    }
    if (store.petMood <= 38) {
      return store.t('home.sad');
    }
    return store.t('home.normal');
  }

  String _hungerLabel(CatudyDemoStore store) {
    return store.petHunger < 35 ? store.t('home.full') : store.t('home.hungry');
  }
}

class _SecondaryHomePanel extends StatelessWidget {
  const _SecondaryHomePanel({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      accentColor: CatudyColors.violet,
      child: Row(
        children: [
          Expanded(
            child: _HomeShortcutButton(
              icon: Icons.groups_rounded,
              label: store.t('community.title'),
              color: CatudyColors.violet,
              onTap: () => context.push('/community?tab=friends'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HomeShortcutButton(
              icon: Icons.workspace_premium_rounded,
              label: store.t('season.title'),
              color: CatudyColors.teal,
              onTap: () => context.push('/season'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _HomeShortcutButton(
              icon: Icons.emoji_events_rounded,
              label: store.t('leaderboard.title'),
              color: CatudyColors.coral,
              onTap: () => context.push('/community?tab=ranking'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeShortcutButton extends StatelessWidget {
  const _HomeShortcutButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CatudyPressable(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyQuickButton extends StatelessWidget {
  const _LobbyQuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CatudyPressable(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
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
    final remaining = progress.remainingMinutes;
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
                  '${store.t('home.dailyGoal')} - ${progress.goalMinutes}',
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
            store.t('home.dailyGoalRemaining', {'left': remaining}),
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
