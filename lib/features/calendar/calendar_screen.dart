import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/notifications/catudy_notification_service.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  bool _openedOnToday = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _visibleMonth = DateTime(today.year, today.month);
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        if (!_openedOnToday && store.isLoaded) {
          _openedOnToday = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            final today = DateTime.now();
            setState(() => _visibleMonth = DateTime(today.year, today.month));
            store.selectCalendarDate(today);
          });
        }
        final selected = store.selectedCalendarDate;
        final selectedRecords = store.recordsForDay(selected);
        final selectedTodos = store.todosForDay(selected);
        final relation = _dayRelation(selected);

        return ScreenScaffold(
          title: store.t('calendar.title'),
          actions: [
            IconButton(
              onPressed: () => context.go('/manual-entry'),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
          children: [
            CatudyPanel(
              accentColor: CatudyColors.violet,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(
                          () => _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month - 1,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          _monthTitle(_visibleMonth, store.languageCode),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: CatudyColors.blue,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () => _visibleMonth = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month + 1,
                          ),
                        ),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final label in _weekdayLabels(store.languageCode))
                        _WeekdayLabel(label),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MonthGrid(
                    visibleMonth: _visibleMonth,
                    selectedDay: selected,
                    store: store,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SelectedDaySummaryCard(
              store: store,
              title: _dayTitle(selected, store.languageCode),
              relation: relation,
              todos: selectedTodos,
              records: selectedRecords,
              onAddReminder: () => _addReminder(context, store, selected),
            ),
            const SizedBox(height: 14),
            _SelectedDayDetailsPanel(
              store: store,
              todos: selectedTodos,
              records: selectedRecords,
            ),
          ],
        );
      },
    );
  }

  _DayRelation _dayRelation(DateTime date) {
    final today = DateTime.now();
    final selectedDay = DateTime(date.year, date.month, date.day);
    final currentDay = DateTime(today.year, today.month, today.day);
    if (selectedDay.isBefore(currentDay)) {
      return _DayRelation.past;
    }
    if (selectedDay.isAfter(currentDay)) {
      return _DayRelation.future;
    }
    return _DayRelation.today;
  }

  Future<void> _addReminder(
    BuildContext context,
    CatudyDemoStore store,
    DateTime selected,
  ) async {
    final draft = await showDialog<_ReminderDraft>(
      context: context,
      builder: (_) =>
          const _ReminderDialog(initialTime: TimeOfDay(hour: 9, minute: 0)),
    );
    if (draft == null) {
      return;
    }
    final todo = store.addTodoReminder(
      date: selected,
      time: draft.time,
      title: draft.title,
    );
    if (todo != null) {
      await CatudyNotificationService.instance.scheduleReminder(
        todo,
        languageCode: store.languageCode,
      );
    }
  }

  String _monthTitle(DateTime date, String languageCode) {
    const trMonths = [
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
    final months = languageCode == 'en' ? enMonths : trMonths;
    return '${months[date.month - 1]} ${date.year}';
  }

  String _dayTitle(DateTime date, String languageCode) {
    return '${date.day} ${_monthTitle(date, languageCode)}';
  }

  List<String> _weekdayLabels(String languageCode) {
    if (languageCode == 'en') {
      return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
    return const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  }
}

enum _DayRelation { past, today, future }

class _SelectedDaySummaryCard extends StatelessWidget {
  const _SelectedDaySummaryCard({
    required this.store,
    required this.title,
    required this.relation,
    required this.todos,
    required this.records,
    required this.onAddReminder,
  });

  final CatudyDemoStore store;
  final String title;
  final _DayRelation relation;
  final List<CalendarTodo> todos;
  final List<FocusRecord> records;
  final VoidCallback onAddReminder;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = records.fold(0, (sum, item) => sum + item.minutes);
    final actionButtons = <Widget>[
      if (relation != _DayRelation.future)
        FilledButton.icon(
          onPressed: () => context.go('/manual-entry'),
          style: FilledButton.styleFrom(backgroundColor: CatudyColors.violet),
          icon: const Icon(Icons.edit_note_rounded),
          label: Text(store.t('calendar.manualAdd')),
        ),
      if (relation != _DayRelation.past)
        FilledButton.icon(
          onPressed: onAddReminder,
          style: FilledButton.styleFrom(backgroundColor: CatudyColors.violet),
          icon: const Icon(Icons.alarm_add_rounded),
          label: Text(store.t('calendar.reminderAdd')),
        ),
    ];

    return CatudyPanel(
      color: CatudyColors.cream,
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: title,
            subtitle: switch (relation) {
              _DayRelation.past => store.t('calendar.pastInfo'),
              _DayRelation.today => store.t('calendar.todayInfo'),
              _DayRelation.future => store.t('calendar.futureInfo'),
            },
            icon: Icons.event_note_rounded,
            accentColor: CatudyColors.teal,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DayMetricPill(
                  icon: Icons.timer_rounded,
                  value: '$totalMinutes${store.t('common.minutesShort')}',
                  label: store.t('calendar.records'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DayMetricPill(
                  icon: Icons.notifications_active_rounded,
                  value: '${todos.length}',
                  label: store.t('calendar.reminders'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: actionButtons),
        ],
      ),
    );
  }
}

class _SelectedDayDetailsPanel extends StatelessWidget {
  const _SelectedDayDetailsPanel({
    required this.store,
    required this.todos,
    required this.records,
  });

  final CatudyDemoStore store;
  final List<CalendarTodo> todos;
  final List<FocusRecord> records;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      accentColor: CatudyColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CatudySectionHeader(
            title: store.t('calendar.reminders'),
            icon: Icons.notifications_none_rounded,
            accentColor: CatudyColors.violet,
          ),
          const SizedBox(height: 10),
          if (todos.isEmpty)
            Text(
              store.t('calendar.noReminders'),
              style: TextStyle(color: CatudyColors.mutedFor(context)),
            )
          else
            for (final todo in todos) _TodoTile(todo: todo, store: store),
          const Divider(height: 26),
          CatudySectionHeader(
            title: store.t('calendar.records'),
            icon: Icons.history_rounded,
            accentColor: CatudyColors.teal,
          ),
          const SizedBox(height: 10),
          if (records.isEmpty)
            Text(
              store.t('calendar.noRecords'),
              style: TextStyle(color: CatudyColors.mutedFor(context)),
            )
          else
            for (final record in records)
              _RecordTile(record: record, store: store),
        ],
      ),
    );
  }
}

class _DayMetricPill extends StatelessWidget {
  const _DayMetricPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CatudyColors.teal.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: CatudyColors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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

class _ReminderDraft {
  const _ReminderDraft({required this.title, required this.time});

  final String title;
  final TimeOfDay time;
}

class _ReminderDialog extends StatefulWidget {
  const _ReminderDialog({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late final TextEditingController _controller;
  late TimeOfDay _time;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _time = widget.initialTime;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _controller.text.trim();
    final hasError = _submitted && title.isEmpty;

    return AlertDialog(
      title: Text(catudyDemoStore.t('calendar.reminderAdd')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 48,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: catudyDemoStore.t('calendar.reminderText'),
              hintText: catudyDemoStore.t('calendar.reminderHint'),
              errorText: hasError
                  ? catudyDemoStore.t('calendar.enterText')
                  : null,
            ),
            onChanged: (_) {
              if (_submitted) {
                setState(() {});
              }
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule_rounded),
            label: Text(
              catudyDemoStore.t('calendar.time', {
                'time': _time.format(context),
              }),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(catudyDemoStore.t('common.cancel')),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: Text(catudyDemoStore.t('common.save')),
        ),
      ],
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _time = picked);
  }

  void _save() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _submitted = true);
      return;
    }
    Navigator.of(context).pop(_ReminderDraft(title: title, time: _time));
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.selectedDay,
    required this.store,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(visibleMonth.year, visibleMonth.month);
    final leading = first.weekday - 1;
    final daysInMonth = DateUtils.getDaysInMonth(first.year, first.month);
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows * 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - leading + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }
        final date = DateTime(first.year, first.month, dayNumber);
        final minutes = store.minutesForDay(date);
        final selected = DateUtils.isSameDay(date, selectedDay);
        final today = DateUtils.isSameDay(date, DateTime.now());
        return InkWell(
          onTap: () => store.selectCalendarDate(date),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            decoration: BoxDecoration(
              color: selected
                  ? CatudyColors.coral.withValues(alpha: 0.20)
                  : minutes > 0
                  ? CatudyColors.violet.withValues(alpha: 0.42)
                  : CatudyColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? CatudyColors.coral
                    : today
                    ? CatudyColors.violet
                    : minutes > 0
                    ? CatudyColors.violet.withValues(alpha: 0.48)
                    : CatudyColors.line,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: selected ? CatudyColors.coral : CatudyColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    minutes == 0
                        ? '-'
                        : '$minutes${store.t('common.minutesShort')}',
                    maxLines: 1,
                    style: const TextStyle(
                      color: CatudyColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
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

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: CatudyColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.store});

  final FocusRecord record;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: store.categoryColor(record.categoryId),
            child: Icon(
              record.manual ? Icons.edit_note_rounded : Icons.timer_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${store.categoryName(record.categoryId)} - ${record.minutes}${store.t('common.minutesShort')}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  record.manual ? 'Manuel - ${record.note}' : record.note,
                  style: const TextStyle(color: CatudyColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({required this.todo, required this.store});

  final CalendarTodo todo;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CatudyColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.14)),
      ),
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
                color: CatudyColors.blue,
                fontWeight: FontWeight.w800,
                decoration: todo.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            '${todo.hour.toString().padLeft(2, '0')}:${todo.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: CatudyColors.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
