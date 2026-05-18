import 'package:flutter/material.dart';

import '../../app/theme/catudy_colors.dart';

class CatudyPanel extends StatelessWidget {
  const CatudyPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = CatudyColors.surface,
    this.accentColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final borderColor = CatudyColors.violet;
    final dark = CatudyColors.isDark(context);
    final panelColor = color == CatudyColors.surface
        ? CatudyColors.surfaceFor(context)
        : color == CatudyColors.cream
        ? CatudyColors.creamFor(context)
        : color == CatudyColors.lavenderSoft
        ? CatudyColors.surfaceStrongFor(context)
        : color;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.22)
                : CatudyColors.violet.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          if (!dark)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.70),
              blurRadius: 2,
              offset: const Offset(0, -1),
            ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: panelColor,
          border: Border.all(
            color: borderColor.withValues(alpha: dark ? 0.30 : 0.24),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: child,
      ),
    );
  }
}
