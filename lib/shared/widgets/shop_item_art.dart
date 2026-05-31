import 'package:flutter/material.dart';

import '../../app/demo/catudy_demo_store.dart';

class ShopItemArt extends StatelessWidget {
  const ShopItemArt({
    super.key,
    required this.item,
    this.size = 52,
    this.showBackground = true,
  });

  final ShopItem item;
  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final assetPath = item.assetPath;
    if (assetPath == null) {
      return _fallbackArt();
    }
    final image = Image.asset(
      assetPath,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      isAntiAlias: true,
      errorBuilder: (_, _, _) => Center(
        child: Icon(item.icon, color: item.accent, size: size * 0.48),
      ),
    );
    if (!showBackground) {
      return SizedBox(width: size, height: size, child: image);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: item.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(color: item.accent.withValues(alpha: 0.16)),
      ),
      child: Padding(padding: EdgeInsets.all(size * 0.08), child: image),
    );
  }

  Widget _fallbackArt() {
    if (!showBackground) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(item.icon, color: item.accent, size: size * 0.48),
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: item.accent.withValues(alpha: 0.22),
      child: Icon(item.icon, color: item.accent, size: size * 0.48),
    );
  }
}
