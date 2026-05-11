import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_info_bubble.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/screen_scaffold.dart';
import '../../shared/widgets/store_builder.dart';

enum StatsRange { week, month, allTime }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsRange _range = StatsRange.week;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder(
      builder: (context, store) {
        final records = _recordsForRange(store.history, _range);
        final minutes = records.fold(0, (sum, item) => sum + item.minutes);
        final sessions = records.where((item) => !item.manual).length;
        final categorySlices = _categorySlices(store, records);
        final chartData = _chartData(store, _range);

        return ScreenScaffold(
          title: store.t('stats.title'),
          actions: [
            IconButton(
              onPressed: () => context.go('/manual-entry'),
              icon: const Icon(Icons.add_chart_rounded),
            ),
          ],
          children: [
            _StatsHero(
              store: store,
              minutes: minutes,
              sessions: sessions,
              streakDays: store.streakDays,
            ),
            const SizedBox(height: 10),
            _RangeTabs(
              store: store,
              selected: _range,
              onChanged: (range) => setState(() => _range = range),
            ),
            const SizedBox(height: 14),
            _PeriodProgressCard(
              store: store,
              range: _range,
              data: chartData,
              totalMinutes: minutes,
            ),
            const SizedBox(height: 14),
            _InsightPanel(store: store, records: records),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.t('stats.categoryDistribution'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: CatudyColors.mutedFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (categorySlices.isEmpty)
                    Text(
                      store.t('stats.noRecordsRange'),
                      style: TextStyle(color: CatudyColors.mutedFor(context)),
                    )
                  else
                    _CategoryPieChart(
                      slices: categorySlices,
                      totalMinutes: minutes,
                      totalLabel: store.t('stats.total'),
                      minutesSuffix: store.t('common.minutesShort'),
                      languageCode: store.languageCode,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CatudyPanel(
              color: CatudyColors.lavenderSoft,
              accentColor: CatudyColors.teal,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: CatudyColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: CatudyColors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      store.t('stats.manualNote'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CatudyColors.mutedFor(context),
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<FocusRecord> _recordsForRange(
    List<FocusRecord> records,
    StatsRange range,
  ) {
    final now = DateTime.now();
    final start = switch (range) {
      StatsRange.week => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6)),
      StatsRange.month => DateTime(now.year, now.month),
      StatsRange.allTime => DateTime(2000),
    };
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return records
        .where(
          (item) =>
              !item.createdAt.isBefore(start) && !item.createdAt.isAfter(end),
        )
        .toList();
  }

  List<_ChartPoint> _chartData(CatudyDemoStore store, StatsRange range) {
    final now = DateTime.now();
    if (range == StatsRange.week) {
      return [
        for (var i = 6; i >= 0; i--)
          _pointForDay(store, now.subtract(Duration(days: i))),
      ];
    }
    if (range == StatsRange.month) {
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      return [
        for (var start = 1; start <= daysInMonth; start += 7)
          _pointForRange(
            store,
            label: '$start-${(start + 6).clamp(1, daysInMonth)}',
            start: DateTime(now.year, now.month, start),
            end: DateTime(
              now.year,
              now.month,
              (start + 6).clamp(1, daysInMonth),
              23,
              59,
              59,
            ),
          ),
      ];
    }
    return [
      for (var i = 5; i >= 0; i--)
        _pointForMonth(store, DateTime(now.year, now.month - i)),
    ];
  }

  _ChartPoint _pointForDay(CatudyDemoStore store, DateTime day) {
    const enLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final records = store.recordsForDay(day);
    final minutes = records.fold(0, (sum, item) => sum + item.minutes);
    return _ChartPoint(
      label: (store.languageCode == 'en' ? enLabels : labels)[day.weekday - 1],
      minutes: minutes,
      title: _weekdayName(day, store.languageCode),
      message: _dayFocusMessage(store, day, records, minutes),
    );
  }

  _ChartPoint _pointForRange(
    CatudyDemoStore store, {
    required String label,
    required DateTime start,
    required DateTime end,
  }) {
    final records = store.history
        .where(
          (item) =>
              !item.createdAt.isBefore(start) && !item.createdAt.isAfter(end),
        )
        .toList();
    final minutes = records.fold(0, (sum, item) => sum + item.minutes);
    final title = store.languageCode == 'en' ? 'Days $label' : '$label. günler';
    return _ChartPoint(
      label: label,
      minutes: minutes,
      title: title,
      message: _rangeFocusMessage(store, title, records, minutes),
    );
  }

  _ChartPoint _pointForMonth(CatudyDemoStore store, DateTime month) {
    const enLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const labels = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    final records = store.history
        .where(
          (item) =>
              item.createdAt.year == month.year &&
              item.createdAt.month == month.month,
        )
        .toList();
    final minutes = records.fold(0, (sum, item) => sum + item.minutes);
    final title = _monthName(month, store.languageCode);
    return _ChartPoint(
      label: (store.languageCode == 'en' ? enLabels : labels)[month.month - 1],
      minutes: minutes,
      title: title,
      message: _rangeFocusMessage(store, title, records, minutes),
    );
  }

  String _dayFocusMessage(
    CatudyDemoStore store,
    DateTime day,
    List<FocusRecord> records,
    int minutes,
  ) {
    final weekday = _weekdayName(day, store.languageCode);
    if (minutes == 0) {
      return store.languageCode == 'en'
          ? 'No focus was recorded on $weekday.'
          : '$weekday günü kayıtlı odak yok.';
    }
    final grouped = _categoryBreakdown(store, records);
    if (grouped.length == 1) {
      final entry = grouped.entries.first;
      return store.languageCode == 'en'
          ? 'On $weekday, you focused for $minutes minutes in ${entry.key}.'
          : '$weekday günü ${entry.key} kategorisinde $minutes dakika odaklandın.';
    }
    final breakdown = _formatBreakdown(store, grouped);
    return store.languageCode == 'en'
        ? 'On $weekday, you focused for $minutes minutes total: $breakdown.'
        : '$weekday günü toplam $minutes dakika odaklandın: $breakdown.';
  }

  String _rangeFocusMessage(
    CatudyDemoStore store,
    String title,
    List<FocusRecord> records,
    int minutes,
  ) {
    if (minutes == 0) {
      return store.languageCode == 'en'
          ? 'No focus was recorded in this period.'
          : 'Bu dönemde kayıtlı odak yok.';
    }
    final grouped = _categoryBreakdown(store, records);
    if (grouped.length == 1) {
      final entry = grouped.entries.first;
      return store.languageCode == 'en'
          ? 'In $title, you focused for $minutes minutes in ${entry.key}.'
          : '$title döneminde ${entry.key} kategorisinde $minutes dakika odaklandın.';
    }
    final breakdown = _formatBreakdown(store, grouped);
    return store.languageCode == 'en'
        ? 'In $title, you focused for $minutes minutes total: $breakdown.'
        : '$title döneminde toplam $minutes dakika odaklandın: $breakdown.';
  }

  Map<String, int> _categoryBreakdown(
    CatudyDemoStore store,
    List<FocusRecord> records,
  ) {
    final grouped = <String, int>{};
    for (final record in records) {
      final name = store.categoryName(record.categoryId);
      grouped[name] = (grouped[name] ?? 0) + record.minutes;
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map<String, int>.fromEntries(entries);
  }

  String _formatBreakdown(CatudyDemoStore store, Map<String, int> grouped) {
    final suffix = store.languageCode == 'en' ? 'min' : 'dk';
    return grouped.entries
        .map((entry) => '${entry.key} ${entry.value}$suffix')
        .join(', ');
  }

  String _weekdayName(DateTime day, String languageCode) {
    const en = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const tr = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return (languageCode == 'en' ? en : tr)[day.weekday - 1];
  }

  String _monthName(DateTime month, String languageCode) {
    const en = [
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
    const tr = [
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
    return (languageCode == 'en' ? en : tr)[month.month - 1];
  }

  List<_CategorySlice> _categorySlices(
    CatudyDemoStore store,
    List<FocusRecord> records,
  ) {
    final slices = <_CategorySlice>[];
    for (final category in store.categories) {
      final minutes = records
          .where((item) => item.categoryId == category.id)
          .fold(0, (sum, item) => sum + item.minutes);
      if (minutes == 0) {
        continue;
      }
      slices.add(
        _CategorySlice(
          name: category.name,
          color: category.color,
          minutes: minutes,
        ),
      );
    }
    slices.sort((a, b) => b.minutes.compareTo(a.minutes));
    return slices;
  }
}

class _PeriodProgressCard extends StatelessWidget {
  const _PeriodProgressCard({
    required this.store,
    required this.range,
    required this.data,
    required this.totalMinutes,
  });

  final CatudyDemoStore store;
  final StatsRange range;
  final List<_ChartPoint> data;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      color: CatudyColors.lavenderSoft,
      accentColor: CatudyColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CatudyColors.violet.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_view_week_rounded,
                  color: CatudyColors.violet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.t(_titleKey),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      store.t(_subtitleKey),
                      style: TextStyle(
                        color: CatudyColors.mutedFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Chip(
            label: Text(
              store.t('stats.periodTotalMinutes', {'minutes': totalMinutes}),
            ),
          ),
          const SizedBox(height: 14),
          _PeriodMiniBars(data: data, store: store),
        ],
      ),
    );
  }

  String get _titleKey => switch (range) {
    StatsRange.week => 'stats.weeklyProgress',
    StatsRange.month => 'stats.monthlyProgress',
    StatsRange.allTime => 'stats.allTimeProgress',
  };

  String get _subtitleKey => switch (range) {
    StatsRange.week => 'stats.lastSevenDays',
    StatsRange.month => 'stats.thisMonth',
    StatsRange.allTime => 'stats.allRecords',
  };
}

class _PeriodMiniBars extends StatelessWidget {
  const _PeriodMiniBars({required this.data, required this.store});

  final List<_ChartPoint> data;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold(
      1,
      (max, item) => item.minutes > max ? item.minutes : max,
    );
    return SizedBox(
      height: 98,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < data.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: CatudyInfoTap(
                  title: data[index].title,
                  message: data[index].message,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        data[index].minutes == 0
                            ? ''
                            : '${data[index].minutes}${store.t('common.minutesShort')}',
                        maxLines: 1,
                        style: TextStyle(
                          color: CatudyColors.mutedFor(context),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: double.infinity,
                            height:
                                16 +
                                (56 *
                                    (data[index].minutes / maxValue).clamp(
                                      0.0,
                                      1.0,
                                    )),
                            decoration: BoxDecoration(
                              color:
                                  (index == data.length - 1
                                          ? CatudyColors.teal
                                          : CatudyColors.violet)
                                      .withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data[index].label,
                        maxLines: 1,
                        style: TextStyle(
                          color: CatudyColors.mutedFor(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsHero extends StatelessWidget {
  const _StatsHero({
    required this.store,
    required this.minutes,
    required this.sessions,
    required this.streakDays,
  });

  final CatudyDemoStore store;
  final int minutes;
  final int sessions;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      color: CatudyColors.cream,
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: CatudyColors.teal.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: CatudyColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  store.t('stats.focusGarden'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: CatudyColors.blueFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  label: store.t('stats.focus'),
                  value: '$minutes${store.t('common.minutesShort')}',
                  info: store.languageCode == 'en'
                      ? 'Total focus duration in the selected range. Manual records appear in reports but stay separate from reward calculations.'
                      : 'Seçili aralıktaki toplam odak süresidir. Manuel kayıtlar raporda görünür ama ödül hesabında ayrı tutulur.',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  label: store.t('stats.sessions'),
                  value: '$sessions',
                  info: store.languageCode == 'en'
                      ? 'Number of completed non-manual focus sessions in the selected range.'
                      : 'Seçili aralıkta tamamlanan manuel olmayan odak seansı sayısıdır.',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  label: store.t('stats.streak'),
                  value: '$streakDays${store.t('common.daysShort')}',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: CatudyColors.coral,
                  info: store.languageCode == 'en'
                      ? 'Shows your regular focus rhythm. The streak grows as you continue without skipping days.'
                      : 'Düzenli odaklanma ritmini gösterir. Gün atlamadan devam ettikçe seri büyür.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.store, required this.records});

  final CatudyDemoStore store;
  final List<FocusRecord> records;

  @override
  Widget build(BuildContext context) {
    final sessions = records.where((item) => !item.manual).toList();
    final total = records.fold(0, (sum, item) => sum + item.minutes);
    final average = sessions.isEmpty ? 0 : (total / sessions.length).round();
    final bestHour = _bestHour(records);
    final goal = store.todayGoalProgress;
    return CatudyPanel(
      color: CatudyColors.lavenderSoft,
      accentColor: CatudyColors.violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            store.t('stats.insights'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InsightChip(
                icon: Icons.av_timer_rounded,
                label: store.t('stats.averageSession'),
                value: '$average${store.t('common.minutesShort')}',
              ),
              _InsightChip(
                icon: Icons.schedule_rounded,
                label: store.t('stats.bestHour'),
                value: bestHour == null
                    ? '-'
                    : '${bestHour.toString().padLeft(2, '0')}:00',
              ),
              _InsightChip(
                icon: Icons.track_changes_rounded,
                label: store.t('stats.todayGoal'),
                value: '${(goal.ratio * 100).round()}%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int? _bestHour(List<FocusRecord> records) {
    if (records.isEmpty) {
      return null;
    }
    final totals = <int, int>{};
    for (final record in records) {
      totals[record.createdAt.hour] =
          (totals[record.createdAt.hour] ?? 0) + record.minutes;
    }
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CatudyColors.violet),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.info,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final String info;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return CatudyInfoTap(
      title: label,
      message: info,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: CatudyColors.surfaceFor(context).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CatudyColors.teal.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: iconColor, size: 22),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    value,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: CatudyColors.blueFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySlice {
  const _CategorySlice({
    required this.name,
    required this.color,
    required this.minutes,
  });

  final String name;
  final Color color;
  final int minutes;
}

class _CategoryPieChart extends StatelessWidget {
  const _CategoryPieChart({
    required this.slices,
    required this.totalMinutes,
    required this.totalLabel,
    required this.minutesSuffix,
    required this.languageCode,
  });

  final List<_CategorySlice> slices;
  final int totalMinutes;
  final String totalLabel;
  final String minutesSuffix;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final pie = SizedBox(
      width: 168,
      height: 168,
      child: CustomPaint(
        painter: _PiePainter(
          slices: slices,
          centerColor: CatudyColors.surfaceFor(context),
          lineColor: CatudyColors.lineFor(context),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$totalMinutes$minutesSuffix',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: CatudyColors.blueFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                totalLabel,
                style: TextStyle(
                  color: CatudyColors.mutedFor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final legend = Column(
      children: [
        for (final slice in slices)
          _CategoryLegendRow(
            slice: slice,
            percent: totalMinutes == 0 ? 0 : slice.minutes / totalMinutes,
            minutesSuffix: minutesSuffix,
            languageCode: languageCode,
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            children: [
              Center(child: pie),
              const SizedBox(height: 14),
              legend,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            pie,
            const SizedBox(width: 18),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({
    required this.slice,
    required this.percent,
    required this.minutesSuffix,
    required this.languageCode,
  });

  final _CategorySlice slice;
  final double percent;
  final String minutesSuffix;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final percentText = '${(percent * 100).round()}%';
    return CatudyInfoTap(
      title: slice.name,
      message: languageCode == 'en'
          ? '${slice.name} has ${slice.minutes}$minutesSuffix of focus and makes up $percentText of the selected range.'
          : '${slice.name} kategorisinde ${slice.minutes}$minutesSuffix çalışıldı; seçili aralığın $percentText kadarını oluşturuyor.',
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: slice.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: slice.color.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: slice.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                slice.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CatudyColors.blueFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${slice.minutes}$minutesSuffix',
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              percentText,
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  const _PiePainter({
    required this.slices,
    required this.centerColor,
    required this.lineColor,
  });

  final List<_CategorySlice> slices;
  final Color centerColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold(0, (sum, slice) => sum + slice.minutes);
    final side = math.min(size.width, size.height);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side,
      height: side,
    ).deflate(5);

    if (total == 0) {
      canvas.drawCircle(
        rect.center,
        rect.width / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 28
          ..color = lineColor,
      );
      return;
    }

    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = (slice.minutes / total) * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()
          ..style = PaintingStyle.fill
          ..color = slice.color,
      );
      start += sweep;
    }

    canvas
      ..drawCircle(rect.center, rect.width * 0.30, Paint()..color = centerColor)
      ..drawCircle(
        rect.center,
        rect.width * 0.31,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = lineColor.withValues(alpha: 0.7),
      );
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.slices != slices ||
        oldDelegate.centerColor != centerColor ||
        oldDelegate.lineColor != lineColor;
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({
    required this.store,
    required this.selected,
    required this.onChanged,
  });

  final CatudyDemoStore store;
  final StatsRange selected;
  final ValueChanged<StatsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: CatudyColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          _RangeTab(
            label: store.t('stats.week'),
            selected: selected == StatsRange.week,
            onTap: () => onChanged(StatsRange.week),
          ),
          _RangeTab(
            label: store.t('stats.month'),
            selected: selected == StatsRange.month,
            onTap: () => onChanged(StatsRange.month),
          ),
          _RangeTab(
            label: store.t('stats.all'),
            selected: selected == StatsRange.allTime,
            onTap: () => onChanged(StatsRange.allTime),
          ),
        ],
      ),
    );
  }
}

class _RangeTab extends StatelessWidget {
  const _RangeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? CatudyColors.violet : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPoint {
  const _ChartPoint({
    required this.label,
    required this.minutes,
    required this.title,
    required this.message,
  });

  final String label;
  final int minutes;
  final String title;
  final String message;
}
