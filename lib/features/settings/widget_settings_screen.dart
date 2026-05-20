import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';
import '../../shared/widgets/floating_mascot.dart';

class WidgetSettingsScreen extends StatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _activeTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pinWidget(CatudyDemoStore store) async {
    final providerName = switch (_activeTab) {
      0 => 'CatudyPetWidgetProvider',
      1 => 'CatudyProgressWidgetProvider',
      _ => 'CatudyShortcutWidgetProvider',
    };

    try {
      await HomeWidget.requestPinWidget(
        name: providerName,
        androidName: providerName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              store.t('widget.pinWidgetSuccess'),
            ),
            backgroundColor: CatudyColors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${store.t('widget.pinWidgetFailed')}: $e'),
            backgroundColor: CatudyColors.coral,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final dark = CatudyColors.isDark(context);

        // Fetch settings from store
        final currentPetId = store.widgetPetId;
        final currentCategoryId = store.widgetShortcutCategoryId;

        // Resolve display pet name and accent color
        String petNameText = '';
        Color petAccent = CatudyColors.violet;
        if (currentPetId == 'active') {
          petNameText = store.petDisplayName;
          petAccent = store.selectedPet.accent;
        } else {
          final matchedPet = store.unlockablePets.firstWhere(
            (p) => p.id == currentPetId,
            orElse: () => store.unlockablePets.first,
          );
          petNameText = matchedPet.name;
          petAccent = matchedPet.accent;
        }

        // Get shortcut category details
        final matchedCategory = store.categories.firstWhere(
          (c) => c.id == currentCategoryId,
          orElse: () => store.categories.first,
        );

        return ScreenScaffold(
          title: store.t('settings.widgetSettingsTitle'),
          showBack: true,
          fallbackBackPath: '/settings',
          showSettingsAction: false,
          children: [
            // Tabs to select widget type
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: CatudyColors.surfaceFor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CatudyColors.lineFor(context),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: CatudyColors.violet.withValues(alpha: 0.16),
                ),
                labelColor: CatudyColors.blueFor(context),
                unselectedLabelColor: CatudyColors.mutedFor(context),
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                padding: const EdgeInsets.all(4),
                tabs: [
                  Tab(text: store.t('widget.tabPet')),
                  Tab(text: store.t('widget.tabProgress')),
                  Tab(text: store.t('widget.tabShortcut')),
                ],
              ),
            ),

            // Premium Live Widget Mockup Box
            Text(
              store.t('widget.previewTitle'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),

            // Elegant smartphone home screen simulation with mock widget
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dark
                      ? [const Color(0xFF1E152A), const Color(0xFF0F0B18)]
                      : [const Color(0xFFE8F0F8), const Color(0xFFCFDEF3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.36 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildWidgetMockup(
                    context: context,
                    store: store,
                    petName: petNameText,
                    petAccent: petAccent,
                    category: matchedCategory,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Configuration Options Panel
            CatudyPanel(
              accentColor: CatudyColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.t('widget.configurations'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: CatudyColors.teal,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const Divider(height: 24),

                  // Pet selection dropdown
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
                      ...store.unlockablePets.map(
                        (pet) => DropdownMenuItem(
                          value: pet.id,
                          child: Text(pet.name),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        store.updateWidgetSettings(
                          petId: val,
                          categoryId: currentCategoryId,
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Shortcut category selection dropdown
                  DropdownButtonFormField<String>(
                    initialValue: currentCategoryId,
                    decoration: InputDecoration(
                      labelText: store.t('widget.shortcutCategoryLabel'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.bolt_rounded),
                    ),
                    items: store.categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: cat.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(cat.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        store.updateWidgetSettings(
                          petId: currentPetId,
                          categoryId: val,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Premium Pin/Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _pinWidget(store),
                style: FilledButton.styleFrom(
                  backgroundColor: CatudyColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.add_to_home_screen_rounded, size: 22),
                label: Text(
                  store.t('widget.pinWidgetButton'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildWidgetMockup({
    required BuildContext context,
    required CatudyDemoStore store,
    required String petName,
    required Color petAccent,
    required FocusCategory category,
  }) {
    final dark = CatudyColors.isDark(context);
    final cardBg = dark ? const Color(0xFF261D35) : Colors.white;
    final textMuted = dark ? Colors.white70 : Colors.black87;

    final session = store.activeSession;
    int activeSessionMinutesLeft = 0;
    if (session != null) {
      final elapsed = DateTime.now().difference(session.startedAt).inMinutes;
      activeSessionMinutesLeft = (session.durationMinutes - elapsed).clamp(0, session.durationMinutes);
    }

    switch (_activeTab) {
      case 0:
        // Pet Status Widget (3x2 aspect style)
        return Container(
          key: const ValueKey('pet_widget'),
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: petAccent.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tinted Floating mascot to match pet selection
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        petAccent.withValues(alpha: 0.25),
                        BlendMode.colorBurn,
                      ),
                      child: const FloatingMascot(width: 80, height: 80),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      petName,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: CatudyColors.blueFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Pet Care status bars
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatBar(
                      context,
                      Icons.favorite_rounded,
                      store.t('widget.petMood'),
                      store.petMood,
                      CatudyColors.coral,
                    ),
                    const SizedBox(height: 6),
                    _buildStatBar(
                      context,
                      Icons.restaurant_rounded,
                      store.t('widget.petHunger'),
                      store.petHunger,
                      CatudyColors.yellow,
                    ),
                    const SizedBox(height: 6),
                    _buildStatBar(
                      context,
                      Icons.bolt_rounded,
                      store.t('widget.petEnergy'),
                      store.petEnergy,
                      CatudyColors.teal,
                    ),
                    const Divider(height: 14, thickness: 1),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: CatudyColors.coral, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${store.streakDays} ${store.t('widget.daysStreak')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 1:
        // Daily Goal Progress Widget (2x2 aspect style)
        final percent = (store.todayMinutes / store.dailyGoalMinutes).clamp(0.0, 1.0);
        return Container(
          key: const ValueKey('progress_widget'),
          width: 200,
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: CatudyColors.teal.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                store.t('widget.dailyGoalTitle'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: CatudyColors.blueFor(context),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 8,
                      backgroundColor: CatudyColors.lineFor(context),
                      valueColor: const AlwaysStoppedAnimation<Color>(CatudyColors.teal),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${store.todayMinutes}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: CatudyColors.blueFor(context),
                          ),
                        ),
                        Text(
                          '/${store.dailyGoalMinutes} dk',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: CatudyColors.mutedFor(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                percent >= 1.0
                    ? store.t('widget.goalCompleted')
                    : '${(percent * 100).toInt()}% ${store.t('widget.completed')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: percent >= 1.0 ? CatudyColors.teal : textMuted,
                ),
              ),
            ],
          ),
        );

      default:
        // Quick Action / Active Focus Widget (3x1 aspect style)
        final sessionRunning = store.activeSession != null;
        return Container(
          key: const ValueKey('shortcut_widget'),
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: category.color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: category.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: CatudyColors.blueFor(context),
                        ),
                      ),
                      Text(
                        store.t('widget.quickFocus'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CatudyColors.mutedFor(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sessionRunning
                      ? CatudyColors.teal.withValues(alpha: 0.15)
                      : CatudyColors.lineFor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sessionRunning ? Icons.timer_rounded : Icons.timer_off_rounded,
                      color: sessionRunning ? CatudyColors.teal : CatudyColors.mutedFor(context),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sessionRunning
                          ? '$activeSessionMinutesLeft ${store.t('widget.minLeft')}'
                          : store.t('widget.idle'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: sessionRunning ? CatudyColors.teal : CatudyColors.mutedFor(context),
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

  Widget _buildStatBar(
    BuildContext context,
    IconData icon,
    String label,
    int val,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: val / 100,
              minHeight: 6,
              backgroundColor: CatudyColors.lineFor(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 24,
          child: Text(
            '$val',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: CatudyColors.mutedFor(context),
            ),
          ),
        ),
      ],
    );
  }
}
