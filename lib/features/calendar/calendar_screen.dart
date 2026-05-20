import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/notifications/catudy_notification_service.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';
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
  final Set<DateTime> _batchSelectedDays = <DateTime>{};

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
        final realMinutes = store.realMinutesForDay(selected);
        final relation = _dayRelation(selected);
        final targetDates = _targetDates(selected);

        return ScreenScaffold(
          title: store.t('calendar.title'),
          actions: [
            IconButton.filledTonal(
              onPressed: () => context.push('/manual-entry'),
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
                    batchSelectedDays: _batchSelectedDays,
                    store: store,
                    onSelectDay: (date) => _selectDay(store, date),
                    onBatchStart: (date) => _startBatchSelection(store, date),
                    onBatchUpdate: (date) => _extendBatchSelection(store, date),
                  ),
                  const SizedBox(height: 10),
                  _CalendarLegend(store: store),
                  if (_batchSelectedDays.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _BatchSelectionBar(
                      count: _batchSelectedDays.length,
                      onClear: () => setState(_batchSelectedDays.clear),
                      store: store,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SelectedDaySummary(
              store: store,
              selected: selected,
              totalMinutes: totalMinutes,
              goalProgressMinutes: realMinutes,
              batchCount: _batchSelectedDays.length,
              onAddRecord: relation == _DayRelation.future
                  ? null
                  : () => _addManualRecord(context, store, targetDates),
              onAddReminder:
                  targetDates.any(
                    (date) => _dayRelation(date) != _DayRelation.past,
                  )
                  ? () => _addReminder(context, store, targetDates)
                  : null,
            ),
            const SizedBox(height: 14),
            _ReminderPanel(todos: todos, store: store),
            const SizedBox(height: 14),
            _SessionTimeline(records: records, store: store),
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

  List<DateTime> _targetDates(DateTime selected) {
    final dates = _batchSelectedDays.isEmpty
        ? <DateTime>[DateTime(selected.year, selected.month, selected.day)]
        : _batchSelectedDays.toList();
    dates.sort();
    return dates;
  }

  void _selectDay(CatudyDemoStore store, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (_batchSelectedDays.isNotEmpty) {
      setState(() {
        if (!_batchSelectedDays.remove(day)) {
          _batchSelectedDays.add(day);
        }
      });
      return;
    }
    store.selectCalendarDate(day);
  }

  void _startBatchSelection(CatudyDemoStore store, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    store.selectCalendarDate(day);
    setState(() {
      _batchSelectedDays
        ..clear()
        ..add(day);
    });
  }

  void _extendBatchSelection(CatudyDemoStore store, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (_batchSelectedDays.contains(day)) {
      return;
    }
    store.selectCalendarDate(day);
    setState(() => _batchSelectedDays.add(day));
  }

  Future<void> _addReminder(
    BuildContext context,
    CatudyDemoStore store,
    List<DateTime> dates,
  ) async {
    final draft = await showDialog<_ReminderDraft>(
      context: context,
      builder: (_) =>
          const _ReminderDialog(initialTime: TimeOfDay(hour: 9, minute: 0)),
    );
    if (draft == null) {
      return;
    }
    final eligibleDates = dates
        .where((date) => _dayRelation(date) != _DayRelation.past)
        .toList();
    for (final date in eligibleDates) {
      final todo = store.addTodoReminder(
        date: date,
        time: draft.time,
        title: draft.title,
      );
      if (todo != null && store.notifications) {
        await CatudyNotificationService.instance.scheduleReminder(
          todo,
          languageCode: store.languageCode,
        );
      }
    }
  }

  Future<void> _addManualRecord(
    BuildContext context,
    CatudyDemoStore store,
    List<DateTime> dates,
  ) async {
    final eligibleDates = dates
        .where((date) => _dayRelation(date) != _DayRelation.future)
        .toList();
    if (eligibleDates.isEmpty) {
      return;
    }
    final draft = await showDialog<_ManualRecordDraft>(
      context: context,
      builder: (_) => _ManualRecordDialog(store: store),
    );
    if (draft == null) {
      return;
    }
    for (final date in eligibleDates) {
      store.addManualEntry(
        categoryId: draft.categoryId,
        minutes: draft.minutes,
        note: draft.note,
        date: date,
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

  List<String> _weekdayLabels(String languageCode) {
    if (languageCode == 'en') {
      return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }
    return const ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  }
}

enum _DayRelation { past, today, future }

class _SelectedDaySummary extends StatelessWidget {
  const _SelectedDaySummary({
    required this.store,
    required this.selected,
    required this.totalMinutes,
    required this.goalProgressMinutes,
    required this.batchCount,
    required this.onAddRecord,
    required this.onAddReminder,
  });

  final CatudyDemoStore store;
  final DateTime selected;
  final int totalMinutes;
  final int goalProgressMinutes;
  final int batchCount;
  final VoidCallback? onAddRecord;
  final VoidCallback? onAddReminder;

  @override
  Widget build(BuildContext context) {
    final goal = store.todayGoalProgress.goalMinutes;
    final remaining = (goal - goalProgressMinutes).clamp(0, 999999);
    return CatudyPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  batchCount > 0
                      ? store.t('calendar.batchSelected', {'count': batchCount})
                      : _compactDateTitle(selected, store.languageCode),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                store.t('calendar.focusCompleted', {'minutes': totalMinutes}),
                style: TextStyle(
                  color: CatudyColors.tealDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: goal == 0 ? 0 : (goalProgressMinutes / goal).clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            color: CatudyColors.teal,
            backgroundColor: CatudyColors.surfaceFor(context),
          ),
          const SizedBox(height: 7),
          Text(
            store.t('home.dailyGoalRemaining', {'left': remaining}),
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onAddRecord != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onAddRecord,
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: Text(store.t('calendar.manualAdd')),
                ),
              if (onAddReminder != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: CatudyColors.violet,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onAddReminder,
                  icon: const Icon(Icons.alarm_add_rounded, size: 18),
                  label: Text(store.t('calendar.reminderAdd')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _compactDateTitle(DateTime date, String languageCode) {
    if (languageCode == 'en') {
      return '${date.month}/${date.day}/${date.year}';
    }
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _BatchSelectionBar extends StatelessWidget {
  const _BatchSelectionBar({
    required this.count,
    required this.onClear,
    required this.store,
  });

  final int count;
  final VoidCallback onClear;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CatudyColors.teal.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CatudyColors.teal.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.touch_app_rounded,
            color: CatudyColors.tealDark,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              store.t('calendar.batchHint', {'count': count}),
              style: TextStyle(
                color: CatudyColors.blueFor(context),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(onPressed: onClear, child: Text(store.t('common.clear'))),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.selectedDay,
    required this.batchSelectedDays,
    required this.store,
    required this.onSelectDay,
    required this.onBatchStart,
    required this.onBatchUpdate,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final Set<DateTime> batchSelectedDays;
  final CatudyDemoStore store;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<DateTime> onBatchStart;
  final ValueChanged<DateTime> onBatchUpdate;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(visibleMonth.year, visibleMonth.month);
    final leading = first.weekday - 1;
    final daysInMonth = DateUtils.getDaysInMonth(first.year, first.month);
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        const crossSpacing = 8.0;
        const mainSpacing = 8.0;
        const aspect = 0.86;
        final cellWidth =
            (constraints.maxWidth - (crossSpacing * 6)).clamp(0, 9999) / 7;
        final cellHeight = cellWidth / aspect;
        final gridHeight = rows * cellHeight + (rows - 1) * mainSpacing;

        DateTime? dateForOffset(Offset offset) {
          final col = (offset.dx / (cellWidth + crossSpacing)).floor();
          final row = (offset.dy / (cellHeight + mainSpacing)).floor();
          if (col < 0 || col > 6 || row < 0 || row >= rows) {
            return null;
          }
          final dayNumber = row * 7 + col - leading + 1;
          if (dayNumber < 1 || dayNumber > daysInMonth) {
            return null;
          }
          return DateTime(first.year, first.month, dayNumber);
        }

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPressStart: (details) {
            final date = dateForOffset(details.localPosition);
            if (date != null) {
              onBatchStart(date);
            }
          },
          onLongPressMoveUpdate: (details) {
            final date = dateForOffset(details.localPosition);
            if (date != null) {
              onBatchUpdate(date);
            }
          },
          child: SizedBox(
            height: gridHeight,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows * 7,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: mainSpacing,
                crossAxisSpacing: crossSpacing,
                childAspectRatio: aspect,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - leading + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final date = DateTime(first.year, first.month, dayNumber);
                final dayKey = DateTime(date.year, date.month, date.day);
                final minutes = store.minutesForDay(date);
                final selected = DateUtils.isSameDay(date, selectedDay);
                final batchSelected = batchSelectedDays.contains(dayKey);
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
                  onTap: () => onSelectDay(date),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      vertical: 3,
                      horizontal: 2,
                    ),
                    decoration: BoxDecoration(
                      color: batchSelected
                          ? CatudyColors.teal.withValues(alpha: 0.30)
                          : selected
                          ? CatudyColors.violet.withValues(alpha: 0.24)
                          : level > 0
                          ? color.withValues(alpha: 0.26)
                          : CatudyColors.surfaceFor(
                              context,
                            ).withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: batchSelected
                            ? CatudyColors.teal
                            : selected
                            ? CatudyColors.teal
                            : today
                            ? CatudyColors.violet
                            : color.withValues(alpha: level > 0 ? 0.38 : 0.16),
                        width: batchSelected || selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: batchSelected || selected
                                ? CatudyColors.teal
                                : CatudyColors.blueFor(context),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (batchSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: CatudyColors.teal,
                          )
                        else if (hasReward)
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
                              color: level == 0
                                  ? CatudyColors.lineFor(context)
                                  : color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
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
          IconButton(
            tooltip: store.t('common.delete'),
            onPressed: () => store.deleteFocusRecord(record.id),
            icon: const Icon(Icons.delete_outline_rounded),
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
          IconButton(
            tooltip: store.t('common.delete'),
            onPressed: () {
              final removed = store.deleteTodo(todo.id);
              if (removed != null) {
                unawaited(
                  CatudyNotificationService.instance.cancelReminder(removed),
                );
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _ManualRecordDraft {
  const _ManualRecordDraft({
    required this.categoryId,
    required this.minutes,
    required this.note,
  });

  final String categoryId;
  final int minutes;
  final String note;
}

class _ManualRecordDialog extends StatefulWidget {
  const _ManualRecordDialog({required this.store});

  final CatudyDemoStore store;

  @override
  State<_ManualRecordDialog> createState() => _ManualRecordDialogState();
}

class _ManualRecordDialogState extends State<_ManualRecordDialog> {
  late String _categoryId;
  late final TextEditingController _minutesController;
  late final TextEditingController _noteController;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.store.selectedCategoryId;
    _minutesController = TextEditingController(text: '25');
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final minutes = int.tryParse(_minutesController.text.trim());
    final hasError = _submitted && (minutes == null || minutes <= 0);
    return AlertDialog(
      title: Text(store.t('calendar.manualAdd')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _categoryId,
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
                      setState(() => _categoryId = value);
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
                      setState(() => _categoryId = categoryId);
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
              errorText: hasError ? store.t('calendar.enterMinutes') : null,
            ),
            onChanged: (_) {
              if (_submitted) {
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: store.t('calendar.recordNote'),
              border: const OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(store.t('common.cancel')),
        ),
        FilledButton(onPressed: _submit, child: Text(store.t('common.save'))),
      ],
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    final minutes = int.tryParse(_minutesController.text.trim());
    if (minutes == null || minutes <= 0) {
      return;
    }
    Navigator.of(context).pop(
      _ManualRecordDraft(
        categoryId: _categoryId,
        minutes: minutes.clamp(1, 720).toInt(),
        note: _noteController.text,
      ),
    );
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
