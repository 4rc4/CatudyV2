import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/notifications/catudy_notification_service.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_visual_system.dart';
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
        final records = store.recordsForDay(selected);
        final todos = store.todosForDay(selected);
        final totalMinutes = records.fold(0, (sum, item) => sum + item.minutes);
        final relation = _dayRelation(selected);

        return ScreenScaffold(
          title: store.t('calendar.title'),
          actions: [
            IconButton.filledTonal(
              onPressed: () => context.go('/manual-entry'),
              icon: const Icon(Icons.add_chart_rounded),
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
                                color: CatudyColors.blueFor(context),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final label in _weekdayLabels(store.languageCode))
                        Expanded(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: CatudyColors.mutedFor(context),
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MonthGrid(
                    visibleMonth: _visibleMonth,
                    selectedDay: selected,
                    store: store,
                  ),
                  const SizedBox(height: 10),
                  _CalendarLegend(store: store),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CatudyStagePanel(
              eyebrow: _dayTitle(selected, store.languageCode),
              title: store.t('calendar.focusCompleted', {
                'minutes': totalMinutes,
              }),
              subtitle: _relationCopy(store, relation),
              icon: Icons.nightlight_round,
              art: const CatudyMascotBadge(
                size: 104,
                accent: CatudyColors.teal,
              ),
              progress: store.todayGoalProgress.goalMinutes == 0
                  ? 0
                  : (totalMinutes / store.todayGoalProgress.goalMinutes).clamp(
                      0.0,
                      1.0,
                    ),
              progressLabel: store.t('home.dailyGoalProgress', {
                'done': totalMinutes,
                'goal': store.todayGoalProgress.goalMinutes,
                'left': (store.todayGoalProgress.goalMinutes - totalMinutes)
                    .clamp(0, 999999),
              }),
              footer: Row(
                children: [
                  Expanded(
                    child: CatudyMetricTile(
                      icon: Icons.star_rounded,
                      label: store.t('season.focusXp'),
                      value: '+$totalMinutes',
                      color: CatudyColors.yellow,
                      dense: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CatudyMetricTile(
                      icon: Icons.monetization_on_rounded,
                      label: store.t('common.gold'),
                      value: '+${totalMinutes ~/ 5}',
                      color: CatudyColors.coral,
                      dense: true,
                    ),
                  ),
                ],
              ),
              actions: [
                if (relation != _DayRelation.future)
                  FilledButton.icon(
                    onPressed: () => context.go('/manual-entry'),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(store.t('calendar.manualAdd')),
                  ),
                if (relation != _DayRelation.past)
                  OutlinedButton.icon(
                    onPressed: () => _addReminder(context, store, selected),
                    icon: const Icon(Icons.alarm_add_rounded),
                    label: Text(store.t('calendar.reminderAdd')),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _SessionTimeline(records: records, store: store),
            const SizedBox(height: 14),
            _ReminderPanel(todos: todos, store: store),
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

  String _relationCopy(CatudyDemoStore store, _DayRelation relation) {
    return switch (relation) {
      _DayRelation.past => store.t('calendar.pastInfo'),
      _DayRelation.today => store.t('calendar.todayInfo'),
      _DayRelation.future => store.t('calendar.futureInfo'),
    };
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
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.86,
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
        final todos = store.todosForDay(date);
        final hasReward = todos.any((todo) => todo.done);
        final level = minutes >= 120
            ? 4
            : minutes >= 60
            ? 3
            : minutes >= 25
            ? 2
            : minutes > 0
            ? 1
            : 0;
        final color = switch (level) {
          4 => CatudyColors.coral,
          3 => CatudyColors.teal,
          2 => CatudyColors.violet,
          1 => CatudyColors.lavender,
          _ => CatudyColors.surfaceFor(context),
        };

        return InkWell(
          onTap: () => store.selectCalendarDate(date),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            decoration: BoxDecoration(
              color: selected
                  ? CatudyColors.violet.withValues(alpha: 0.24)
                  : level > 0
                  ? color.withValues(alpha: 0.26)
                  : CatudyColors.surfaceFor(context).withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? CatudyColors.teal
                    : today
                    ? CatudyColors.violet
                    : color.withValues(alpha: level > 0 ? 0.38 : 0.16),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: selected
                        ? CatudyColors.teal
                        : CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                if (hasReward)
                  const Icon(
                    Icons.inventory_2_rounded,
                    size: 13,
                    color: CatudyColors.yellow,
                  )
                else if (selected)
                  Image.asset(
                    'assets/brand/catudy-mascot.png',
                    width: 13,
                    height: 13,
                  )
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: level == 0 ? CatudyColors.lineFor(context) : color,
                      shape: BoxShape.circle,
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

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 9,
      runSpacing: 8,
      children: [
        _LegendDot(
          label: '0 ${store.t('common.minutesShort')}',
          color: CatudyColors.lineFor(context),
        ),
        _LegendDot(
          label: '1-25 ${store.t('common.minutesShort')}',
          color: CatudyColors.lavender,
        ),
        _LegendDot(
          label: '25-60 ${store.t('common.minutesShort')}',
          color: CatudyColors.violet,
        ),
        _LegendDot(
          label: '60-120 ${store.t('common.minutesShort')}',
          color: CatudyColors.teal,
        ),
        _LegendDot(
          label: '120+ ${store.t('common.minutesShort')}',
          color: CatudyColors.coral,
        ),
        _LegendDot(
          label: store.t('calendar.rewardDay'),
          color: CatudyColors.yellow,
          icon: Icons.inventory_2_rounded,
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon == null
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            : Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: CatudyColors.mutedFor(context),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SessionTimeline extends StatelessWidget {
  const _SessionTimeline({required this.records, required this.store});

  final List<FocusRecord> records;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.t('calendar.sessions'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (records.isEmpty)
            Text(
              store.t('calendar.noRecords'),
              style: TextStyle(color: CatudyColors.mutedFor(context)),
            )
          else
            for (final record in records)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecordTile(record: record, store: store),
              ),
        ],
      ),
    );
  }
}

class _ReminderPanel extends StatelessWidget {
  const _ReminderPanel({required this.todos, required this.store});

  final List<CalendarTodo> todos;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      accentColor: CatudyColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.t('calendar.reminders'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (todos.isEmpty)
            Text(
              store.t('calendar.noReminders'),
              style: TextStyle(color: CatudyColors.mutedFor(context)),
            )
          else
            for (final todo in todos) _TodoTile(todo: todo, store: store),
        ],
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
    final time =
        '${record.createdAt.hour.toString().padLeft(2, '0')}:${record.createdAt.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            record.manual ? Icons.edit_note_rounded : Icons.menu_book_rounded,
            color: store.categoryColor(record.categoryId),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$time · ${store.categoryName(record.categoryId)}',
                  style: TextStyle(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  record.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: CatudyColors.mutedFor(context)),
                ),
              ],
            ),
          ),
          Chip(
            label: Text('${record.minutes} ${store.t('common.minutesShort')}'),
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
        color: CatudyColors.surfaceFor(context).withValues(alpha: 0.76),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
