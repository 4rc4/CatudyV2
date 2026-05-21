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
  const FocusStartScreen({super.key, this.unlockPackageName});

  final String? unlockPackageName;

  @override
  State<FocusStartScreen> createState() => _FocusStartScreenState();
}

class _FocusStartScreenState extends State<FocusStartScreen> {
  late final TextEditingController _minutesController;

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
    final unlockPackageName = widget.unlockPackageName;
    if (unlockPackageName != null && unlockPackageName.isNotEmpty) {
      catudyDemoStore.prepareAppUnlockFocus(unlockPackageName);
      _minutesController.text = '${catudyDemoStore.selectedDurationMinutes}';
    }
  }

  @override
  void dispose() {
    _minutesController.dispose();
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
                  _PrimaryStartFocusButton(
                    label: store.t('focus.start'),
                    minutes: store.selectedDurationMinutes,
                    categoryColor: store.selectedCategory.color,
                    onPressed: () => _start(store),
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
                    crossAxisAlignment: WrapCrossAlignment.center,
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
                      ChoiceChip(
                        label: const Icon(Icons.add_rounded, size: 20),
                        selected: false,
                        onSelected: (_) =>
                            _showAddCategoryDialog(context, store),
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
                      ChoiceChip(
                        label: Text(
                          store.durations.contains(
                                store.selectedDurationMinutes,
                              )
                              ? store.t('focus.customDuration')
                              : '${store.selectedDurationMinutes} ${store.t('common.minutesShort')}',
                        ),
                        selected: !store.durations.contains(
                          store.selectedDurationMinutes,
                        ),
                        avatar: const Icon(Icons.edit_rounded, size: 16),
                        onSelected: (_) =>
                            _showCustomDurationDialog(context, store),
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
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, CatudyDemoStore store) {
    showDialog(
      context: context,
      builder: (context) {
        Color selectedColor = CatudyColors.violet;
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                store.t('focus.addCategoryOpen'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: store.t('focus.categoryName'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.label_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    store.t('focus.customCategory'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CatudyColors.mutedFor(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color in _palette)
                        InkWell(
                          onTap: () => setState(() => selectedColor = color),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor == color
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: AnimatedScale(
                              scale: selectedColor == color ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(store.t('common.cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      store.addCategory(name, selectedColor);
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(store.t('focus.addCategory')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCustomDurationDialog(BuildContext context, CatudyDemoStore store) {
    final controller = TextEditingController(
      text: store.durations.contains(store.selectedDurationMinutes)
          ? ''
          : '${store.selectedDurationMinutes}',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            store.t('focus.customDuration'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: store.t('focus.customMinutes'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.timer_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(store.t('common.cancel')),
            ),
            FilledButton(
              onPressed: () {
                final minutes = int.tryParse(controller.text);
                if (minutes != null && minutes > 0) {
                  _selectDuration(store, minutes.clamp(1, 240));
                  Navigator.of(context).pop();
                }
              },
              child: Text(store.t('common.save')),
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

class _PrimaryStartFocusButton extends StatefulWidget {
  const _PrimaryStartFocusButton({
    required this.label,
    required this.minutes,
    required this.categoryColor,
    required this.onPressed,
  });

  final String label;
  final int minutes;
  final Color categoryColor;
  final VoidCallback onPressed;

  @override
  State<_PrimaryStartFocusButton> createState() =>
      _PrimaryStartFocusButtonState();
}

class _PrimaryStartFocusButtonState extends State<_PrimaryStartFocusButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
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
            duration: const Duration(milliseconds: 130),
            height: 74,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [widget.categoryColor, CatudyColors.violet],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.categoryColor.withValues(
                    alpha: _pressed ? 0.16 : 0.28,
                  ),
                  blurRadius: _pressed ? 10 : 22,
                  offset: Offset(0, _pressed ? 5 : 12),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.38),
                width: 1.6,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: widget.categoryColor,
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
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.minutes} min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w800,
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
