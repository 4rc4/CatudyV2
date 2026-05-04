import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/catudy_assets.dart';
import '../../app/demo/catudy_demo_store.dart';
import '../../app/notifications/catudy_notification_service.dart';
import '../../app/theme/catudy_colors.dart';
import '../../features/onboarding/pet_intro_tour.dart';
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
      builder: (context, store) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset(CatudyAssets.logo, width: 46, height: 46),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    store.t('home.greeting'),
                    style: textTheme.headlineSmall?.copyWith(
                      color: CatudyColors.blueFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => showPetIntroTour(context),
                  tooltip: store.t('pet.showTour'),
                  style: IconButton.styleFrom(
                    backgroundColor: CatudyColors.surfaceFor(context),
                    foregroundColor: CatudyColors.mutedFor(context),
                  ),
                  icon: const Icon(Icons.info_rounded),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => context.go('/settings'),
                  tooltip: store.t('pet.settings'),
                  style: IconButton.styleFrom(
                    backgroundColor: CatudyColors.surfaceFor(context),
                    foregroundColor: CatudyColors.mutedFor(context),
                  ),
                  icon: const Icon(Icons.settings_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CatudyPanel(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              color: CatudyColors.cream,
              accentColor: CatudyColors.teal,
              child: Row(
                children: [
                  const FloatingMascot(width: 72, height: 72),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _PetStatusChip(
                          icon: Icons.sentiment_satisfied_rounded,
                          label:
                              '${store.t('home.happiness')}: ${store.petMood > 70 ? store.t('home.good') : store.t('home.normal')}',
                          infoTitle: store.t('home.happiness'),
                          infoMessage:
                              'Mochi odak seansları ve sevdiği eşyalarla daha mutlu olur. Mutluluk yüksekken oda daha canlı hissettirir.',
                        ),
                        _PetStatusChip(
                          icon: Icons.local_cafe_rounded,
                          label:
                              '${store.t('home.hunger')}: ${store.petHunger < 35 ? store.t('home.full') : store.t('home.hungry')}',
                          infoTitle: store.t('home.hunger'),
                          infoMessage:
                              'Açlık zamanla yükselir. Düzenli odak ve bakım petin dengesini korur.',
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => context.go('/pet-room'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CatudyColors.violet,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(store.t('home.petButton')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            CatudyPanel(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              accentColor: CatudyColors.teal,
              child: Column(
                children: [
                  const _SparkleDivider(),
                  Text(
                    store.t('home.focusTime'),
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.hourglass_bottom_rounded,
                        color: CatudyColors.teal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${store.selectedDurationMinutes} ${store.t('common.minutes')}',
                        style: textTheme.titleLarge?.copyWith(
                          color: CatudyColors.mutedFor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _FocusLaunchButton(
                    onPressed: () => context.go('/focus/category'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: store.t('home.createLobby'),
                    icon: Icons.home_rounded,
                    color: CatudyColors.violet,
                    onPressed: () => context.go('/lobby/create'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: store.t('home.joinLobby'),
                    icon: Icons.groups_rounded,
                    color: CatudyColors.teal,
                    onPressed: () => context.go('/lobby/join'),
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
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.violet,
              child: Column(
                children: [
                  Text(
                    store.t('home.todaySummary'),
                    style: textTheme.titleLarge?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SummaryText(
                        label: store.t('home.focus'),
                        value:
                            '${store.todayMinutes}${store.t('common.minutesShort')}',
                        info:
                            'Bugün tamamlanan gerçek ve manuel odak kayıtlarının toplam süresi.',
                      ),
                      _SummaryText(
                        label: store.t('home.streak'),
                        icon: Icons.local_fire_department_rounded,
                        value:
                            '${store.streakDays}${store.t('common.daysShort')}',
                        info:
                            'Art arda odak yapılan günleri gösterir. Seri ilerledikçe motivasyon takibi kolaylaşır.',
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  Text(
                    store.history.isEmpty
                        ? store.t('home.noSessions')
                        : store.t('home.lastSession', {
                            'minutes': store.history.first.minutes,
                          }),
                    style: textTheme.bodyLarge?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CatudyPanel(
              color: CatudyColors.lavenderSoft,
              accentColor: CatudyColors.lavender,
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: CatudyColors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.local_cafe_rounded,
                      color: CatudyColors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.t('home.breakTitle'),
                          style: textTheme.titleMedium?.copyWith(
                            color: CatudyColors.mutedFor(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          store.t('home.breakBody'),
                          style: textTheme.bodyMedium?.copyWith(
                            color: CatudyColors.mutedFor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
  const _FocusLaunchButton({required this.onPressed});

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
          scale: _pressed ? 0.94 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
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
            child: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: Icon(icon, size: 22),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  const _SummaryText({
    required this.label,
    required this.value,
    required this.info,
    this.icon,
  });

  final String label;
  final String value;
  final String info;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return CatudyInfoTap(
      title: label,
      message: info,
      child: Column(
        children: [
          Text(label, style: TextStyle(color: CatudyColors.mutedFor(context))),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: CatudyColors.coral, size: 22),
                const SizedBox(width: 3),
              ],
              Text(
                value,
                style: TextStyle(
                  color: CatudyColors.blueFor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparkleDivider extends StatelessWidget {
  const _SparkleDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('*', style: TextStyle(color: CatudyColors.teal)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
