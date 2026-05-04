import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                DropdownButtonFormField<String>(
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
