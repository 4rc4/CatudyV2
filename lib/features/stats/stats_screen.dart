import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/demo/catudy_demo_store.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_info_bubble.dart';
import '../../shared/widgets/catudy_panel.dart';
import '../../shared/widgets/catudy_section_header.dart';
import '../../shared/widgets/catudy_test_ad_banner.dart';
import '../../shared/widgets/catudy_visual_system.dart';
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
        final effectiveRange = store.hasPremiumAccess
            ? _range
            : StatsRange.week;
        final records = _recordsForRange(store.history, effectiveRange);
        final minutes = records.fold(0, (sum, item) => sum + item.minutes);
        final sessions = records.where((item) => !item.manual).length;
        final average = sessions == 0 ? 0 : (minutes / sessions).round();
        final chartData = _chartData(store, effectiveRange);
        final categorySlices = _categorySlices(store, records);
        final best = chartData.fold<_ChartPoint?>(
          null,
          (best, item) =>
              best == null || item.minutes > best.minutes ? item : best,
        );

        return ScreenScaffold(
          title: store.t('stats.title'),
          actions: [
            IconButton.filledTonal(
              onPressed: () => context.push('/manual-entry'),
              icon: const Icon(Icons.add_chart_rounded),
            ),
          ],
          children: [
            CatudyVisualTabs<StatsRange>(
              selected: effectiveRange,
              onChanged: (range) {
                if (!store.hasPremiumAccess && range != StatsRange.week) {
                  context.push('/plus?from=stats');
                  return;
                }
                setState(() => _range = range);
              },
              tabs: [
                CatudyVisualTab(
                  value: StatsRange.week,
                  label: store.t('stats.week'),
                  icon: Icons.calendar_view_week_rounded,
                ),
                CatudyVisualTab(
                  value: StatsRange.month,
                  label: store.t('stats.month'),
                  icon: Icons.calendar_month_rounded,
                ),
                CatudyVisualTab(
                  value: StatsRange.allTime,
                  label: store.t('stats.all'),
                  icon: Icons.all_inclusive_rounded,
                ),
              ],
            ),
            if (!store.hasPremiumAccess) ...[
              const SizedBox(height: 12),
              _PremiumStatsUpsell(store: store),
            ],
            const SizedBox(height: 14),
            CatudyStagePanel(
              eyebrow: store.t(_rangeLabelKey(effectiveRange)),
              title: store.t('stats.dashboardTitle', {'minutes': minutes}),
              subtitle: best == null || best.minutes == 0
                  ? store.t('stats.noRecordsRange')
                  : store.t('stats.bestDayInsight', {
                      'day': best.label,
                      'minutes': best.minutes,
                    }),
              art: const CatudyMascotBadge(size: 92, accent: CatudyColors.teal),
              footer: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _InfoMetricTile(
                        title: store.t('stats.sessions'),
                        message: store.t('stats.sessionsInfo', {
                          'count': sessions,
                        }),
                        child: CatudyMetricTile(
                          icon: Icons.check_circle_rounded,
                          label: store.t('stats.sessions'),
                          value: '$sessions',
                          caption: store.t('stats.sessionsDelta'),
                          color: CatudyColors.teal,
                          dense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoMetricTile(
                        title: store.t('stats.averageSession'),
                        message: store.t('stats.averageSessionInfo', {
                          'minutes': average,
                        }),
                        child: CatudyMetricTile(
                          icon: Icons.schedule_rounded,
                          label: store.t('stats.averageSession'),
                          value: '$average${store.t('common.minutesShort')}',
                          caption: store.t('stats.averageDelta'),
                          color: CatudyColors.violet,
                          dense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoMetricTile(
                        title: store.t('stats.bestDay'),
                        message: best == null
                            ? store.t('stats.bestDayInfoEmpty')
                            : store.t('stats.bestDayInfo', {
                                'day': best.label,
                                'minutes': best.minutes,
                              }),
                        child: CatudyMetricTile(
                          icon: Icons.star_rounded,
                          label: store.t('stats.bestDay'),
                          value: best?.label ?? '-',
                          caption: best == null
                              ? null
                              : '${best.minutes}${store.t('common.minutesShort')}',
                          color: CatudyColors.yellow,
                          dense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CatudyTestAdBanner(show: !store.hasPremiumAccess),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.teal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CatudySectionHeader(
                    title: store.t('stats.focusTimeThisPeriod'),
                    icon: Icons.bar_chart_rounded,
                    accentColor: CatudyColors.teal,
                    trailing: Chip(
                      label: Text(
                        store.t('stats.periodTotalMinutes', {
                          'minutes': minutes,
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CatudyInfoTap(
                    title: store.t('stats.focusTimeThisPeriod'),
                    message: store.t('stats.focusedTimeInfo', {
                      'minutes': minutes,
                    }),
                    child: _FocusBarChart(data: chartData, store: store),
                  ),
                  const SizedBox(height: 12),
                  _InsightStrip(
                    icon: Icons.pets_rounded,
                    text: best == null || best.minutes == 0
                        ? store.t('stats.emptyMochiInsight')
                        : store.t('stats.mochiBestInsight', {
                            'day': best.label,
                          }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CatudyPanel(
              accentColor: CatudyColors.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CatudySectionHeader(
                    title: store.t('stats.categoryDistribution'),
                    icon: Icons.donut_large_rounded,
                    accentColor: CatudyColors.violet,
                  ),
                  const SizedBox(height: 14),
                  if (categorySlices.isEmpty)
                    Text(
                      store.t('stats.noRecordsRange'),
                      style: TextStyle(color: CatudyColors.mutedFor(context)),
                    )
                  else
                    CatudyInfoTap(
                      title: store.t('stats.categoryDistribution'),
                      message: store.t('stats.categoryDistributionInfo'),
                      child: _CategoryDonut(
                        slices: categorySlices,
                        totalMinutes: minutes,
                        minutesSuffix: store.t('common.minutesShort'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            CatudyStagePanel(
              title: store.t('stats.coachInsight'),
              subtitle: store.hasPremiumAccess
                  ? '${store.coachRecommendation.headline} ${store.coachRecommendation.reason}'
                  : store.t('stats.plusLocked'),
              icon: Icons.auto_awesome_rounded,
              accentColor: CatudyColors.coral,
              secondaryColor: CatudyColors.violet,
              actions: [
                if (!store.hasPremiumAccess)
                  FilledButton.icon(
                    onPressed: () => context.push('/plus?from=stats'),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: Text(store.t('stats.openPlus')),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _rangeLabelKey(StatsRange range) => switch (range) {
    StatsRange.week => 'stats.weeklyProgress',
    StatsRange.month => 'stats.monthlyProgress',
    StatsRange.allTime => 'stats.allTimeProgress',
  };

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
    const trLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final records = store.recordsForDay(day);
    return _ChartPoint(
      label: (store.languageCode == 'en'
          ? enLabels
          : trLabels)[day.weekday - 1],
      minutes: records.fold(0, (sum, item) => sum + item.minutes),
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
    return _ChartPoint(
      label: label,
      minutes: records.fold(0, (sum, item) => sum + item.minutes),
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
    const trLabels = [
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
    return _ChartPoint(
      label: (store.languageCode == 'en'
          ? enLabels
          : trLabels)[month.month - 1],
      minutes: records.fold(0, (sum, item) => sum + item.minutes),
    );
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

class _FocusBarChart extends StatelessWidget {
  const _FocusBarChart({required this.data, required this.store});

  final List<_ChartPoint> data;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold(
      1,
      (max, item) => item.minutes > max ? item.minutes : max,
    );
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in data)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CatudyInfoTap(
                  title: point.label,
                  message: store.t('stats.dayFocusInfo', {
                    'minutes': point.minutes,
                  }),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        point.minutes == 0
                            ? ''
                            : '${point.minutes}${store.t('common.minutesShort')}',
                        style: TextStyle(
                          color: CatudyColors.mutedFor(context),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: double.infinity,
                            height: 24 + (112 * (point.minutes / maxValue)),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  CatudyColors.teal,
                                  CatudyColors.violet,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CatudyColors.teal.withValues(
                                    alpha: 0.20,
                                  ),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        point.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: CatudyColors.mutedFor(context),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
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

class _CategoryDonut extends StatelessWidget {
  const _CategoryDonut({
    required this.slices,
    required this.totalMinutes,
    required this.minutesSuffix,
  });

  final List<_CategorySlice> slices;
  final int totalMinutes;
  final String minutesSuffix;

  @override
  Widget build(BuildContext context) {
    final chart = SizedBox(
      width: 156,
      height: 156,
      child: CustomPaint(
        painter: _DonutPainter(
          slices: slices,
          centerColor: CatudyColors.surfaceFor(context),
          lineColor: CatudyColors.lineFor(context),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/brand/catudy-mascot.png', width: 38),
              Text(
                '$totalMinutes$minutesSuffix',
                style: TextStyle(
                  color: CatudyColors.blueFor(context),
                  fontWeight: FontWeight.w900,
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
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: slice.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slice.name,
                    style: TextStyle(
                      color: CatudyColors.blueFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${totalMinutes == 0 ? 0 : ((slice.minutes / totalMinutes) * 100).round()}%',
                  style: TextStyle(
                    color: CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(children: [chart, const SizedBox(height: 14), legend]);
        }
        return Row(
          children: [
            chart,
            const SizedBox(width: 18),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceStrongFor(context).withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: CatudyColors.violet),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoMetricTile extends StatelessWidget {
  const _InfoMetricTile({
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 142,
      child: CatudyInfoTap(title: title, message: message, child: child),
    );
  }
}

class _PremiumStatsUpsell extends StatelessWidget {
  const _PremiumStatsUpsell({required this.store});

  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    return CatudyPanel(
      color: CatudyColors.cream,
      accentColor: CatudyColors.violet,
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: CatudyColors.violet),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              store.t('stats.plusLocked'),
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/plus?from=stats'),
            child: Text(store.t('stats.openPlus')),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
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
    ).deflate(8);

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
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 26
          ..color = slice.color,
      );
      start += sweep;
    }

    canvas
      ..drawCircle(rect.center, rect.width * 0.28, Paint()..color = centerColor)
      ..drawCircle(
        rect.center,
        rect.width * 0.29,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = lineColor.withValues(alpha: 0.7),
      );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.slices != slices ||
        oldDelegate.centerColor != centerColor ||
        oldDelegate.lineColor != lineColor;
  }
}

class _ChartPoint {
  const _ChartPoint({required this.label, required this.minutes});

  final String label;
  final int minutes;
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
