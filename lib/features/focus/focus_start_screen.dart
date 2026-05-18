import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class FocusStartScreen extends StatefulWidget {
  const FocusStartScreen({super.key});

  @override
  State<FocusStartScreen> createState() => _FocusStartScreenState();
}

class _FocusStartScreenState extends State<FocusStartScreen> {
  late final TextEditingController _minutesController;
  final _categoryController = TextEditingController();
  Color _selectedColor = CatudyColors.violet;
  bool _showAdvanced = false;

  static const _palette = [
    CatudyColors.violet,
    CatudyColors.teal,
    CatudyColors.coral,
    CatudyColors.yellow,
    CatudyColors.lavender,
  ];

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(
      text: '${catudyDemoStore.selectedDurationMinutes}',
    );
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        return ScreenScaffold(
          title: store.t('focus.startComposerTitle'),
          showBack: true,
          fallbackBackPath: '/',
          children: [
            CatudyPanel(
              color: CatudyColors.lavenderSoft,
              accentColor: CatudyColors.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CatudySectionHeader(
                    title: store.t('focus.readyTitle'),
                    subtitle: store.t('focus.readyBody', {
                      'category': store.selectedCategory.name,
                      'minutes': store.selectedDurationMinutes,
                    }),
                    icon: Icons.play_circle_fill_rounded,
                    accentColor: CatudyColors.violet,
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _start(store),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(store.t('focus.start')),
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
                  CatudySectionHeader(
                    title: store.t('focus.categoryTitle'),
                    icon: Icons.category_rounded,
                    accentColor: CatudyColors.teal,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in store.categories)
                        ChoiceChip(
                          label: Text(category.name),
                          selected: store.selectedCategoryId == category.id,
                          avatar: Icon(
                            _iconFor(category.id),
                            color: store.selectedCategoryId == category.id
                                ? category.color
                                : CatudyColors.mutedFor(context),
                            size: 18,
                          ),
                          onSelected: (_) => store.selectCategory(category.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.coral,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CatudySectionHeader(
                    title: store.t('focus.durationTitle'),
                    icon: Icons.timer_rounded,
                    accentColor: CatudyColors.coral,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final minutes in store.durations)
                        ChoiceChip(
                          label: Text(
                            '$minutes${store.t('common.minutesShort')}',
                          ),
                          selected: store.selectedDurationMinutes == minutes,
                          onSelected: (_) => _selectDuration(store, minutes),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.tealDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CatudySectionHeader(
                    title: store.t('focus.taskTitle'),
                    icon: Icons.task_alt_rounded,
                    accentColor: CatudyColors.tealDark,
                  ),
                  const SizedBox(height: 12),
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
            OutlinedButton.icon(
              onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
              icon: Icon(
                _showAdvanced ? Icons.expand_less_rounded : Icons.tune_rounded,
              ),
              label: Text(
                _showAdvanced
                    ? store.t('focus.hideAdvanced')
                    : store.t('focus.showAdvanced'),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _showAdvanced
                  ? Padding(
                      key: const ValueKey('advanced'),
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        children: [
                          CatudyPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.t('focus.customDuration'),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: CatudyColors.blueFor(context),
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _minutesController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: store.t('focus.customMinutes'),
                                    prefixIcon: const Icon(
                                      Icons.edit_calendar_rounded,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    final minutes = int.tryParse(value);
                                    if (minutes == null || minutes <= 0) {
                                      return;
                                    }
                                    store.selectDuration(
                                      minutes.clamp(1, 240).toInt(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          CatudyPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.t('focus.customCategory'),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: CatudyColors.blueFor(context),
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _categoryController,
                                  decoration: InputDecoration(
                                    labelText: store.t('focus.categoryName'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final color in _palette)
                                      InkWell(
                                        onTap: () => setState(
                                          () => _selectedColor = color,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: _selectedColor == color
                                                  ? CatudyColors.blueFor(
                                                      context,
                                                    )
                                                  : Colors.white,
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  onPressed: () {
                                    store.addCategory(
                                      _categoryController.text,
                                      _selectedColor,
                                    );
                                    _categoryController.clear();
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: Text(store.t('focus.addCategory')),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _start(store),
                icon: const Icon(Icons.timer_rounded),
                label: Text(store.t('focus.startTimer')),
              ),
            ),
          ],
        );
      },
    );
  }

  void _selectDuration(CatudyDemoStore store, int minutes) {
    store.selectDuration(minutes);
    final text = '$minutes';
    if (_minutesController.text == text) {
      return;
    }
    _minutesController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _start(CatudyDemoStore store) {
    final focusRoute = store.consumeFocusNavigationRoute();
    if (focusRoute != null) {
      context.go(focusRoute);
      return;
    }
    store.startFocus();
    context.go('/focus/timer');
  }

  IconData _iconFor(String id) {
    return switch (id) {
      'work' => Icons.laptop_mac_rounded,
      'read' => Icons.menu_book_rounded,
      'math' => Icons.calculate_rounded,
      _ => Icons.school_rounded,
    };
  }
}
