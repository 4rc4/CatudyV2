import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class DurationScreen extends StatefulWidget {
  const DurationScreen({super.key});

  @override
  State<DurationScreen> createState() => _DurationScreenState();
}

class _DurationScreenState extends State<DurationScreen> {
  late final TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(
      text: catudyDemoStore.selectedDurationMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

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
          CatudyPanel(
            accentColor: CatudyColors.teal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.t('focus.taskTitle'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (store.openFocusTasks.isEmpty)
                  Text(
                    store.t('focus.noOpenTasks'),
                    style: TextStyle(color: CatudyColors.mutedFor(context)),
                  )
                else
                  DropdownButtonFormField<String?>(
                    initialValue: store.selectedFocusTodo?.id,
                    decoration: InputDecoration(
                      labelText: store.t('focus.selectTask'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(store.t('focus.noTaskSelected')),
                      ),
                      for (final todo in store.openFocusTasks)
                        DropdownMenuItem<String?>(
                          value: todo.id,
                          child: Text(
                            todo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: store.selectTodoForFocus,
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
                _DurationCard(
                  minutes: minutes,
                  onSelected: () => _selectDuration(store, minutes),
                ),
            ],
          ),
          const SizedBox(height: 14),
          CatudyPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.t('focus.customDuration'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: store.t('focus.customMinutes'),
                    prefixIcon: const Icon(Icons.edit_calendar_rounded),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value);
                    if (minutes == null || minutes <= 0) {
                      return;
                    }
                    store.selectDuration(minutes.clamp(1, 240).toInt());
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  store.t('focus.selectedDuration', {
                    'minutes': store.selectedDurationMinutes,
                  }),
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                final focusRoute = store.consumeFocusNavigationRoute();
                if (focusRoute != null) {
                  context.go(focusRoute);
                  return;
                }
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

  void _selectDuration(CatudyDemoStore store, int minutes) {
    final normalized = minutes.clamp(1, 240).toInt();
    store.selectDuration(normalized);
    final text = '$normalized';
    if (_minutesController.text == text) {
      return;
    }
    _minutesController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _DurationCard extends StatelessWidget {
  const _DurationCard({required this.minutes, required this.onSelected});

  final int minutes;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final selected = store.selectedDurationMinutes == minutes;
        return InkWell(
          onTap: onSelected,
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
