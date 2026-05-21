import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_pressable.dart';
import '../../shared/widgets/floating_mascot.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

enum _WidgetKind { pet, goal, shortcut, streak, wallet }

class WidgetSettingsScreen extends StatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  _WidgetKind _activeKind = _WidgetKind.pet;

  Future<void> _pinWidget(CatudyDemoStore store) async {
    final providerName = switch (_activeKind) {
      _WidgetKind.pet => 'CatudyPetWidgetProvider',
      _WidgetKind.goal => 'CatudyProgressWidgetProvider',
      _WidgetKind.shortcut => 'CatudyShortcutWidgetProvider',
      _WidgetKind.streak => 'CatudyStreakWidgetProvider',
      _WidgetKind.wallet => 'CatudyWalletWidgetProvider',
    };

    try {
      await HomeWidget.requestPinWidget(
        name: providerName,
        androidName: providerName,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(store.t('widget.pinWidgetSuccess')),
          backgroundColor: CatudyColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${store.t('widget.pinWidgetFailed')}: $error'),
          backgroundColor: CatudyColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final currentPetId = store.widgetPetId;
        final currentCategoryId = store.widgetShortcutCategoryId;
        final pet = currentPetId == 'active'
            ? store.selectedPet
            : store.unlockablePets.firstWhere(
                (item) => item.id == currentPetId,
                orElse: () => store.selectedPet,
              );
        final petName = currentPetId == 'active'
            ? store.petDisplayName
            : pet.name;
        final category = store.categories.firstWhere(
          (item) => item.id == currentCategoryId,
          orElse: () => store.categories.first,
        );

        return ScreenScaffold(
          title: store.t('settings.widgetSettingsTitle'),
          showBack: true,
          fallbackBackPath: '/settings',
          showSettingsAction: false,
          children: [
            _WidgetKindSelector(
              store: store,
              selected: _activeKind,
              onSelected: (kind) => setState(() => _activeKind = kind),
            ),
            const SizedBox(height: 14),
            _WidgetPreviewStage(
              child: _WidgetMockup(
                kind: _activeKind,
                store: store,
                petName: petName,
                petAccent: pet.accent,
                category: category,
              ),
            ),
            const SizedBox(height: 14),
            _WidgetOptionsPanel(
              store: store,
              currentPetId: currentPetId,
              currentCategoryId: currentCategoryId,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _pinWidget(store),
                icon: const Icon(Icons.add_to_home_screen_rounded),
                label: Text(store.t('widget.pinWidgetButton')),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WidgetKindSelector extends StatelessWidget {
  const _WidgetKindSelector({
    required this.store,
    required this.selected,
    required this.onSelected,
  });

  final CatudyDemoStore store;
  final _WidgetKind selected;
  final ValueChanged<_WidgetKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _WidgetKind.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final kind = _WidgetKind.values[index];
          final active = kind == selected;
          final color = _kindColor(kind);
          return SizedBox(
            width: 112,
            child: CatudyPressable(
              child: InkWell(
                onTap: () => onSelected(kind),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: active ? color : CatudyColors.surfaceFor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active
                          ? Colors.white.withValues(alpha: 0.42)
                          : color.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      if (active)
                        BoxShadow(
                          color: color.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _kindIcon(kind),
                        color: active ? Colors.white : color,
                        size: 25,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _kindLabel(store, kind),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : CatudyColors.blueFor(context),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WidgetPreviewStage extends StatelessWidget {
  const _WidgetPreviewStage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = CatudyColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF171326) : const Color(0xFFE9F6F4),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: CatudyColors.teal.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: child,
        ),
      ),
    );
  }
}

class _WidgetOptionsPanel extends StatelessWidget {
  const _WidgetOptionsPanel({
    required this.store,
    required this.currentPetId,
    required this.currentCategoryId,
  });

  final CatudyDemoStore store;
  final String currentPetId;
  final String currentCategoryId;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: CatudyColors.teal),
              const SizedBox(width: 8),
              Text(
                store.t('widget.configurations'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: CatudyColors.blueFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: currentPetId,
            decoration: InputDecoration(
              labelText: store.t('widget.petLockLabel'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.pets_rounded),
            ),
            items: [
              DropdownMenuItem(
                value: 'active',
                child: Text(store.t('widget.petLockFollowActive')),
              ),
              for (final pet in store.unlockablePets)
                DropdownMenuItem(value: pet.id, child: Text(pet.name)),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              store.updateWidgetSettings(
                petId: value,
                categoryId: currentCategoryId,
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: currentCategoryId,
            decoration: InputDecoration(
              labelText: store.t('widget.shortcutCategoryLabel'),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.bolt_rounded),
            ),
            items: [
              for (final category in store.categories)
                DropdownMenuItem(
                  value: category.id,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              store.updateWidgetSettings(
                petId: currentPetId,
                categoryId: value,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WidgetMockup extends StatelessWidget {
  _WidgetMockup({
    required this.kind,
    required this.store,
    required this.petName,
    required this.petAccent,
    required this.category,
  }) : super(key: ValueKey(kind));

  final _WidgetKind kind;
  final CatudyDemoStore store;
  final String petName;
  final Color petAccent;
  final FocusCategory category;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      _WidgetKind.pet => _PetWidgetPreview(
        store: store,
        petName: petName,
        petAccent: petAccent,
      ),
      _WidgetKind.goal => _GoalWidgetPreview(store: store),
      _WidgetKind.shortcut => _ShortcutWidgetPreview(
        store: store,
        category: category,
      ),
      _WidgetKind.streak => _StreakWidgetPreview(store: store),
      _WidgetKind.wallet => _WalletWidgetPreview(store: store),
    };
  }
}

class _PetWidgetPreview extends StatelessWidget {
  const _PetWidgetPreview({
    required this.store,
    required this.petName,
    required this.petAccent,
  });

  final CatudyDemoStore store;
  final String petName;
  final Color petAccent;

  @override
  Widget build(BuildContext context) {
    return _WidgetCard(
      width: 320,
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FloatingMascot(width: 70, height: 70),
                Text(
                  petName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatBar(
                  icon: Icons.favorite_rounded,
                  value: store.petMood,
                  color: CatudyColors.coral,
                ),
                const SizedBox(height: 8),
                _StatBar(
                  icon: Icons.restaurant_rounded,
                  value: 100 - store.petHunger,
                  color: CatudyColors.yellow,
                ),
                const SizedBox(height: 8),
                _StatBar(
                  icon: Icons.bolt_rounded,
                  value: store.petEnergy,
                  color: CatudyColors.teal,
                ),
                const SizedBox(height: 10),
                _InlinePill(
                  icon: Icons.local_fire_department_rounded,
                  label:
                      '${store.streakDays}${store.t('common.daysShort')} ${store.t('stats.streak')}',
                  color: petAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalWidgetPreview extends StatelessWidget {
  const _GoalWidgetPreview({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final progress = store.todayGoalProgress.ratio;
    return _WidgetCard(
      width: 210,
      height: 210,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            store.t('widget.dailyGoalTitle'),
            style: TextStyle(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox.square(
            dimension: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 9,
                  backgroundColor: CatudyColors.lineFor(context),
                  color: CatudyColors.teal,
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${store.todayMinutes}/${store.dailyGoalMinutes}${store.t('common.minutesShort')}',
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutWidgetPreview extends StatelessWidget {
  const _ShortcutWidgetPreview({required this.store, required this.category});

  final CatudyDemoStore store;
  final FocusCategory category;

  @override
  Widget build(BuildContext context) {
    final session = store.activeSession;
    final minutesLeft = session == null
        ? 0
        : (session.durationMinutes -
                  DateTime.now().difference(session.startedAt).inMinutes)
              .clamp(0, session.durationMinutes);
    return _WidgetCard(
      width: 320,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow_rounded, color: category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  store.t('widget.quickFocus'),
                  style: TextStyle(color: CatudyColors.mutedFor(context)),
                ),
              ],
            ),
          ),
          _InlinePill(
            icon: session == null
                ? Icons.timer_off_rounded
                : Icons.timer_rounded,
            label: session == null
                ? store.t('widget.idle')
                : '$minutesLeft ${store.t('widget.minLeft')}',
            color: session == null ? CatudyColors.violet : CatudyColors.teal,
          ),
        ],
      ),
    );
  }
}

class _StreakWidgetPreview extends StatelessWidget {
  const _StreakWidgetPreview({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return _WidgetCard(
      width: 210,
      height: 170,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: CatudyColors.coral,
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            '${store.streakDays}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            store.t('stats.streak'),
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletWidgetPreview extends StatelessWidget {
  const _WalletWidgetPreview({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return _WidgetCard(
      width: 280,
      child: Row(
        children: [
          const Icon(
            Icons.savings_rounded,
            color: CatudyColors.violet,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${store.gold} ${store.t('common.gold')}',
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${store.focusPoints} ${store.t('common.points')}',
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetCard extends StatelessWidget {
  const _WidgetCard({required this.child, required this.width, this.height});

  final Widget child;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0, 100) / 100,
              minHeight: 8,
              backgroundColor: CatudyColors.lineFor(context),
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlinePill extends StatelessWidget {
  const _InlinePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _kindLabel(CatudyDemoStore store, _WidgetKind kind) => switch (kind) {
  _WidgetKind.pet => store.t('widget.kind.pet'),
  _WidgetKind.goal => store.t('widget.kind.goal'),
  _WidgetKind.shortcut => store.t('widget.kind.shortcut'),
  _WidgetKind.streak => store.t('widget.kind.streak'),
  _WidgetKind.wallet => store.t('widget.kind.wallet'),
};

IconData _kindIcon(_WidgetKind kind) => switch (kind) {
  _WidgetKind.pet => Icons.pets_rounded,
  _WidgetKind.goal => Icons.track_changes_rounded,
  _WidgetKind.shortcut => Icons.flash_on_rounded,
  _WidgetKind.streak => Icons.local_fire_department_rounded,
  _WidgetKind.wallet => Icons.savings_rounded,
};

Color _kindColor(_WidgetKind kind) => switch (kind) {
  _WidgetKind.pet => CatudyColors.violet,
  _WidgetKind.goal => CatudyColors.teal,
  _WidgetKind.shortcut => CatudyColors.tealDark,
  _WidgetKind.streak => CatudyColors.coral,
  _WidgetKind.wallet => CatudyColors.violetDark,
};
