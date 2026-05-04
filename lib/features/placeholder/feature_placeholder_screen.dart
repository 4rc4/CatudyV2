import 'package:flutter/material.dart';

import '../../app/catudy_assets.dart';
import '../../app/theme/catudy_colors.dart';
import '../../shared/widgets/catudy_panel.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.showMascot = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool showMascot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              color: CatudyColors.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          CatudyPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  '$title module placeholder',
                  style: textTheme.titleLarge?.copyWith(
                    color: CatudyColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: CatudyColors.muted,
                    height: 1.55,
                  ),
                ),
                if (showMascot) ...[
                  const SizedBox(height: 22),
                  Center(
                    child: Image.asset(
                      CatudyAssets.mascot,
                      width: 150,
                      height: 150,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
