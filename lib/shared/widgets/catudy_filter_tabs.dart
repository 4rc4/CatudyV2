import 'package:flutter/material.dart';

import '../../app/theme/catudy_colors.dart';

class CatudyFilterTab<T> {
  const CatudyFilterTab({
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

class CatudyFilterTabs<T> extends StatelessWidget {
  const CatudyFilterTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<CatudyFilterTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tab in tabs)
          _CatudyFilterChip<T>(
            tab: tab,
            selected: tab.value == selected,
            onTap: () => onChanged(tab.value),
          ),
      ],
    );
  }
}

class _CatudyFilterChip<T> extends StatelessWidget {
  const _CatudyFilterChip({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final CatudyFilterTab<T> tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : CatudyColors.mutedFor(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? CatudyColors.violet
              : CatudyColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? CatudyColors.violet
                : CatudyColors.violet.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, color: foreground, size: 17),
            const SizedBox(width: 6),
            Text(
              tab.label,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w900),
            ),
            if (tab.count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : CatudyColors.violet.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tab.count}',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
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
