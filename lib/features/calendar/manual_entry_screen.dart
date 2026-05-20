import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _minutesController = TextEditingController(text: '30');
  final _noteController = TextEditingController(text: 'Manuel çalışma');

  @override
  void dispose() {
    _minutesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) => ScreenScaffold(
        title: store.t('manual.title'),
        showBack: true,
        fallbackBackPath: '/calendar',
        children: [
          CatudyPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.t('manual.info'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CatudyColors.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final initial = store.selectedCalendarDate.isAfter(now)
                        ? now
                        : store.selectedCalendarDate;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2020),
                      lastDate: now,
                    );
                    if (picked != null) {
                      store.selectCalendarDate(picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    _formatDate(store.selectedCalendarDate, store.languageCode),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: store.selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: store.t('manual.category'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final category in store.categories)
                            DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            store.selectCategory(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          final categoryId = await _showQuickCategoryDialog(
                            context,
                            store,
                          );
                          if (categoryId != null) {
                            store.selectCategory(categoryId);
                          }
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: Text(store.t('focus.addCategory')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: store.t('manual.minutes'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: store.t('manual.note'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () {
                    final minutes = int.tryParse(_minutesController.text) ?? 0;
                    if (minutes <= 0) {
                      return;
                    }
                    store.addManualEntry(
                      categoryId: store.selectedCategoryId,
                      minutes: minutes,
                      note: _noteController.text,
                      date: store.selectedCalendarDate.isAfter(DateTime.now())
                          ? DateTime.now()
                          : store.selectedCalendarDate,
                    );
                    context.go('/calendar');
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(store.t('manual.save')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, String languageCode) {
    const enMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final names = languageCode == 'en' ? enMonths : months;
    return '${date.day} ${names[date.month - 1]} ${date.year}';
  }
}

Future<String?> _showQuickCategoryDialog(
  BuildContext context,
  CatudyDemoStore store,
) async {
  final controller = TextEditingController();
  var selectedColor = CatudyColors.violet;
  const palette = [
    CatudyColors.violet,
    CatudyColors.teal,
    CatudyColors.coral,
    CatudyColors.yellow,
    CatudyColors.lavender,
  ];

  try {
    return await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(store.t('focus.addCategory')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: store.t('focus.categoryName'),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitQuickCategory(
                  dialogContext,
                  store,
                  controller.text,
                  selectedColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in palette)
                    InkWell(
                      onTap: () => setDialogState(() => selectedColor = color),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedColor == color
                                ? CatudyColors.blueFor(context)
                                : Colors.white,
                            width: 3,
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(store.t('common.cancel')),
            ),
            FilledButton(
              onPressed: () => _submitQuickCategory(
                dialogContext,
                store,
                controller.text,
                selectedColor,
              ),
              child: Text(store.t('focus.addCategory')),
            ),
          ],
        ),
      ),
    );
  } finally {
    controller.dispose();
  }
}

void _submitQuickCategory(
  BuildContext context,
  CatudyDemoStore store,
  String name,
  Color color,
) {
  if (name.trim().isEmpty) {
    return;
  }
  store.addCategory(name, color);
  Navigator.of(context).pop(store.selectedCategoryId);
}
