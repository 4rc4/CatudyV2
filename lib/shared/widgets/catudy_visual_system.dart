import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/catudy_assets.dart';
import '../../app/theme/catudy_colors.dart';

class CatudyStagePanel extends StatelessWidget {
  const CatudyStagePanel({
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.icon,
    this.art,
    this.actions = const [],
    this.footer,
    this.progress,
    this.progressLabel,
    this.accentColor = CatudyColors.violet,
    this.secondaryColor = CatudyColors.teal,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final IconData? icon;
  final Widget? art;
  final List<Widget> actions;
  final Widget? footer;
  final double? progress;
  final String? progressLabel;
  final Color accentColor;
  final Color secondaryColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final dark = CatudyColors.isDark(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: CatudyColors.surfaceStrongFor(context),
        border: Border.all(
          color: CatudyColors.violet.withValues(alpha: dark ? 0.30 : 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.20 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          if (!dark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.58),
              blurRadius: 2,
              offset: const Offset(0, -1),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                CatudyAssetSlot(
                  icon: icon,
                  accentColor: accentColor,
                  size: 48,
                  compact: true,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (eyebrow != null) ...[
                      Text(
                        eyebrow!,
                        style: TextStyle(
                          color: secondaryColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: CatudyColors.blueFor(context),
                            fontWeight: FontWeight.w900,
                            height: 1.04,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: CatudyColors.mutedFor(context),
                          fontWeight: FontWeight.w800,
                          height: 1.28,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (art != null) ...[const SizedBox(width: 12), art!],
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 12,
                color: secondaryColor,
                backgroundColor: CatudyColors.surfaceFor(context),
              ),
            ),
            if (progressLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                progressLabel!,
                style: TextStyle(
                  color: CatudyColors.mutedFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
          if (footer != null) ...[const SizedBox(height: 14), footer!],
        ],
      ),
    );
  }
}

class CatudyAssetSlot extends StatelessWidget {
  const CatudyAssetSlot({
    this.assetPath,
    this.icon,
    this.child,
    this.accentColor = CatudyColors.violet,
    this.size = 96,
    this.compact = false,
    super.key,
  });

  final String? assetPath;
  final IconData? icon;
  final Widget? child;
  final Color accentColor;
  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? size * 0.34 : size * 0.24;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(compact ? 9 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: CatudyColors.surfaceFor(context),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child:
          child ??
          (assetPath != null
              ? Image.asset(assetPath!, fit: BoxFit.contain)
              : Icon(
                  icon ?? Icons.auto_awesome_rounded,
                  color: accentColor,
                  size: compact ? size * 0.44 : size * 0.50,
                )),
    );
  }
}

class CatudyMetricTile extends StatelessWidget {
  const CatudyMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.color = CatudyColors.teal,
    this.dense = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dense ? 10 : 12),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: dense ? 20 : 24),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: CatudyColors.blueFor(context),
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w800,
              fontSize: 12,
              height: 1.18,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Text(
              caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CatudyVisualTab<T> {
  const CatudyVisualTab({
    required this.value,
    required this.label,
    required this.icon,
    this.count,
  });

  final T value;
  final String label;
  final IconData icon;
  final int? count;
}

class CatudyVisualTabs<T> extends StatelessWidget {
  const CatudyVisualTabs({
    required this.selected,
    required this.tabs,
    required this.onChanged,
    this.accentColor = CatudyColors.violet,
    super.key,
  });

  final T selected;
  final List<CatudyVisualTab<T>> tabs;
  final ValueChanged<T> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: CatudyColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CatudyColors.violet.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: _VisualTabButton<T>(
                tab: tab,
                selected: tab.value == selected,
                accentColor: accentColor,
                onTap: () => onChanged(tab.value),
              ),
            ),
        ],
      ),
    );
  }
}

class CatudyRewardRail extends StatelessWidget {
  const CatudyRewardRail({
    required this.freeItems,
    required this.premiumItems,
    required this.currentValue,
    this.accentColor = CatudyColors.teal,
    super.key,
  });

  final List<CatudyRewardRailItem> freeItems;
  final List<CatudyRewardRailItem> premiumItems;
  final int currentValue;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final maxCount = math.max(freeItems.length, premiumItems.length);
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned(
            left: (constraints.maxWidth - 2) / 2,
            top: 22,
            bottom: 26,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                color: CatudyColors.lineFor(context),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Column(
            children: [
              for (var index = 0; index < maxCount; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: index < freeItems.length
                            ? _RewardRailCard(item: freeItems[index])
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 7),
                      _RailNode(
                        index: index + 1,
                        active:
                            (index < freeItems.length &&
                                freeItems[index].threshold <= currentValue) ||
                            (index < premiumItems.length &&
                                premiumItems[index].threshold <= currentValue),
                        color: accentColor,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: index < premiumItems.length
                            ? _RewardRailCard(item: premiumItems[index])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class CatudyRewardRailItem {
  const CatudyRewardRailItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.threshold,
    required this.claimed,
    required this.unlocked,
    required this.locked,
    required this.onClaim,
    required this.actionLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int threshold;
  final bool claimed;
  final bool unlocked;
  final bool locked;
  final VoidCallback? onClaim;
  final String actionLabel;
}

class CatudyMascotBadge extends StatelessWidget {
  const CatudyMascotBadge({
    this.size = 92,
    this.accent = CatudyColors.violet,
    super.key,
  });

  final double size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CatudyAssetSlot(
      size: size,
      accentColor: accent,
      child: Image.asset(CatudyAssets.mascot, fit: BoxFit.contain),
    );
  }
}

class _RewardRailCard extends StatelessWidget {
  const _RewardRailCard({required this.item});

  final CatudyRewardRailItem item;

  @override
  Widget build(BuildContext context) {
    final dimmed = item.locked || !item.unlocked;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: dimmed ? 0.72 : 1,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: CatudyColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CatudyColors.violet.withValues(alpha: 0.24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CatudyColors.blueFor(context),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      height: 1.12,
                    ),
                  ),
                ),
                Icon(
                  item.locked
                      ? Icons.lock_rounded
                      : item.claimed
                      ? Icons.check_circle_rounded
                      : item.unlocked
                      ? Icons.redeem_rounded
                      : Icons.hourglass_bottom_rounded,
                  color: item.locked
                      ? CatudyColors.mutedFor(context)
                      : item.claimed
                      ? CatudyColors.teal
                      : item.color,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (item.onClaim != null && item.unlocked && !item.claimed) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: FilledButton(
                  onPressed: item.onClaim,
                  child: Text(item.actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RailNode extends StatelessWidget {
  const _RailNode({
    required this.index,
    required this.active,
    required this.color,
  });

  final int index;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? color.withValues(alpha: 0.22)
                : CatudyColors.surfaceFor(context),
            border: Border.all(
              color: active ? color : CatudyColors.lineFor(context),
              width: active ? 3 : 1.2,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Text(
            '$index',
            style: TextStyle(
              color: active ? color : CatudyColors.mutedFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisualTabButton<T> extends StatelessWidget {
  const _VisualTabButton({
    required this.tab,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final CatudyVisualTab<T> tab;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: selected
              ? LinearGradient(
                  colors: [accentColor, CatudyColors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab.icon,
              size: 16,
              color: selected ? Colors.white : CatudyColors.mutedFor(context),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : CatudyColors.mutedFor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
            if (tab.count != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : CatudyColors.surfaceStrongFor(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tab.count}',
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : CatudyColors.mutedFor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
