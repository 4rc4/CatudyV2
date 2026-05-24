import 'package:flutter/material.dart';

import '../../app/catudy_assets.dart';
import '../../app/catudy_pet_accessories.dart';

class CatudyPetAvatar extends StatelessWidget {
  const CatudyPetAvatar({
    super.key,
    this.equippedItemId,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.high,
  });

  final String? equippedItemId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final accessoryPath = CatudyPetAccessories.alignedAssetPathFor(
      equippedItemId,
    );
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Image.asset(
            CatudyAssets.mascot,
            fit: fit,
            filterQuality: filterQuality,
            isAntiAlias: true,
          ),
          if (accessoryPath != null)
            Image.asset(
              accessoryPath,
              fit: fit,
              filterQuality: filterQuality,
              isAntiAlias: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
