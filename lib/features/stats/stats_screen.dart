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
            const SizedBox(height: 14),
            _RangeTabs(
              store: store,
              selected: _range,
              onChanged: (range) => setState(() => _range = range),
            ),
            const SizedBox(height: 14),
            _FocusChart(
              data: _chartData(store.history, _range, store.languageCode),
              title: store.t('stats.focusRhythm'),
              store: store,
            ),
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

  List<_ChartPoint> _chartData(
    List<FocusRecord> records,
    StatsRange range,
    String languageCode,
  ) {
    final now = DateTime.now();
    if (range == StatsRange.week) {
      return [
        for (var i = 6; i >= 0; i--)
          _pointForDay(records, now.subtract(Duration(days: i)), languageCode),
      ];
    }
    if (range == StatsRange.month) {
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      return [
        for (var start = 1; start <= daysInMonth; start += 7)
          _ChartPoint(
            '$start-${(start + 6).clamp(1, daysInMonth)}',
            records
                .where(
                  (item) =>
                      item.createdAt.year == now.year &&
                      item.createdAt.month == now.month &&
                      item.createdAt.day >= start &&
                      item.createdAt.day <= (start + 6).clamp(1, daysInMonth),
                )
                .fold(0, (sum, item) => sum + item.minutes),
          ),
      ];
    }
    return [
      for (var i = 5; i >= 0; i--)
        _pointForMonth(
          records,
          DateTime(now.year, now.month - i),
          languageCode,
        ),
    ];
  }

  _ChartPoint _pointForDay(
    List<FocusRecord> records,
    DateTime day,
    String languageCode,
  ) {
    const enLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const labels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return _ChartPoint(
      (languageCode == 'en' ? enLabels : labels)[day.weekday - 1],
      records
          .where(
            (item) =>
                item.createdAt.year == day.year &&
                item.createdAt.month == day.month &&
                item.createdAt.day == day.day,
          )
          .fold(0, (sum, item) => sum + item.minutes),
    );
  }

  _ChartPoint _pointForMonth(
    List<FocusRecord> records,
    DateTime month,
    String languageCode,
  ) {
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
    return _ChartPoint(
      (languageCode == 'en' ? enLabels : labels)[month.month - 1],
      records
          .where(
            (item) =>
                item.createdAt.year == month.year &&
                item.createdAt.month == month.month,
          )
          .fold(0, (sum, item) => sum + item.minutes),
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
                  info:
                      'Seçili aralıktaki toplam odak süresidir. Manuel kayıtlar raporda görünür ama ödül hesabında ayrı tutulur.',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  label: store.t('stats.sessions'),
                  value: '$sessions',
                  info:
                      'Seçili aralıkta tamamlanan manuel olmayan odak seansı sayısıdır.',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricPill(
                  label: store.t('stats.streak'),
                  value: '$streakDays${store.t('common.daysShort')}',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: CatudyColors.coral,
                  info:
                      'Düzenli odaklanma ritmini gösterir. Gün atlamadan devam ettikçe seri büyür.',
                ),
              ),
            ],
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
  });

  final List<_CategorySlice> slices;
  final int totalMinutes;
  final String totalLabel;
  final String minutesSuffix;

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
  });

  final _CategorySlice slice;
  final double percent;
  final String minutesSuffix;

  @override
  Widget build(BuildContext context) {
    final percentText = '${(percent * 100).round()}%';
    return CatudyInfoTap(
      title: slice.name,
      message:
          '${slice.name} kategorisi seçili aralıktaki toplam odak süresinin $percentText kadarını oluşturuyor.',
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

class _FocusChart extends StatelessWidget {
  const _FocusChart({
    required this.data,
    required this.title,
    required this.store,
  });

  final List<_ChartPoint> data;
  final String title;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold(
      1,
      (max, item) => item.minutes > max ? item.minutes : max,
    );

    return CatudyPanel(
      accentColor: CatudyColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < data.length; index++)
                  Expanded(
                    child: _ChartColumn(
                      label: data[index].label,
                      minutes: data[index].minutes,
                      ratio: data[index].minutes / maxValue,
                      selected: index == data.length - 1,
                      store: store,
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

class _ChartPoint {
  const _ChartPoint(this.label, this.minutes);

  final String label;
  final int minutes;
}

class _ChartColumn extends StatelessWidget {
  const _ChartColumn({
    required this.label,
    required this.minutes,
    required this.ratio,
    required this.selected,
    required this.store,
  });

  final String label;
  final int minutes;
  final double ratio;
  final bool selected;
  final CatudyDemoStore store;

  @override
  Widget build(BuildContext context) {
    final color = selected ? CatudyColors.teal : CatudyColors.violet;
    return CatudyInfoTap(
      title: store.languageCode == 'en' ? '$label focus' : '$label odağı',
      message: minutes == 0
          ? 'Bu zaman diliminde kayıtlı odak yok.'
          : 'Bu zaman diliminde toplam $minutes dakika odak kaydı var.',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              minutes == 0 ? '' : '$minutes${store.t('common.minutesShort')}',
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              height: 20 + (74 * ratio.clamp(0.0, 1.0)),
              decoration: BoxDecoration(
                color: color.withValues(alpha: selected ? 0.82 : 0.34),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
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
    );
  }
}
