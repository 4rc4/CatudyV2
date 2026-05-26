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

  static const _mascotSourceSize = Size(311, 466);
  static const _accessoryTopOverflow = 180.0;
  static const _accessoryCanvasSourceSize = Size(311, 646);
  static const _accessoryTopOverflowRatio = 180 / 466;
  static const _accessoryCanvasHeightRatio = 646 / 466;

  @override
  Widget build(BuildContext context) {
    final accessory = CatudyPetAccessories.byId(equippedItemId ?? '');
    final placement = CatudyPetAccessories.placementFor(equippedItemId);
    final trimmedPath = CatudyPetAccessories.trimmedAssetPathFor(
      equippedItemId,
    );
    final alignedPath = CatudyPetAccessories.alignedAssetPathFor(
      equippedItemId,
    );
    return SizedBox(
      width: width,
      height: height == null ? null : height! * _accessoryCanvasHeightRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxSize = constraints.biggest;
          if (!boxSize.width.isFinite || !boxSize.height.isFinite) {
            return Image.asset(
              CatudyAssets.mascot,
              fit: fit,
              filterQuality: filterQuality,
              isAntiAlias: true,
            );
          }
          final reservesOverflow = height != null;
          final catSlotSize = Size(
            boxSize.width,
            reservesOverflow
                ? boxSize.height / _accessoryCanvasHeightRatio
                : boxSize.height,
          );
          final topOverflow = reservesOverflow
              ? catSlotSize.height * _accessoryTopOverflowRatio
              : 0.0;
          final fitted = applyBoxFit(fit, _mascotSourceSize, catSlotSize);
          final mascotSize = fitted.destination;
          final mascotLeft = (catSlotSize.width - mascotSize.width) / 2;
          final mascotTop =
              topOverflow + (catSlotSize.height - mascotSize.height) / 2;
          final mascotScale = mascotSize.width / _mascotSourceSize.width;
          final canvasLeft = mascotLeft;
          final canvasTop = mascotTop - _accessoryTopOverflow * mascotScale;
          final canvasSize = _accessoryCanvasSourceSize * mascotScale;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: mascotLeft,
                top: mascotTop,
                width: mascotSize.width,
                height: mascotSize.height,
                child: Image.asset(
                  CatudyAssets.mascot,
                  fit: BoxFit.fill,
                  filterQuality: filterQuality,
                  isAntiAlias: true,
                ),
              ),
              if (accessory != null && alignedPath != null)
                _AlignedAccessoryLayer(
                  path: alignedPath,
                  left: canvasLeft,
                  top: canvasTop,
                  width: canvasSize.width,
                  height: canvasSize.height,
                  filterQuality: filterQuality,
                )
              else if (placement != null && trimmedPath != null)
                _AnchoredAccessoryLayer(
                  path: trimmedPath,
                  placement: placement,
                  canvasLeft: canvasLeft,
                  canvasTop: canvasTop,
                  scale: mascotScale,
                  filterQuality: filterQuality,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AnchoredAccessoryLayer extends StatelessWidget {
  const _AnchoredAccessoryLayer({
    required this.path,
    required this.placement,
    required this.canvasLeft,
    required this.canvasTop,
    required this.scale,
    required this.filterQuality,
  });

  final String path;
  final CatudyPetAccessoryPlacement placement;
  final double canvasLeft;
  final double canvasTop;
  final double scale;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final anchor = Offset(
      canvasLeft + placement.targetAnchor.dx * scale,
      canvasTop +
          (placement.targetAnchor.dy + CatudyPetAvatar._accessoryTopOverflow) *
              scale,
    );
    final accessoryWidth =
        placement.targetWidth * placement.scaleMultiplier * scale;
    return Positioned(
      left: anchor.dx,
      top: anchor.dy,
      width: accessoryWidth,
      child: FractionalTranslation(
        translation: Offset(
          -placement.sourceAnchor.dx,
          -placement.sourceAnchor.dy,
        ),
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          filterQuality: filterQuality,
          isAntiAlias: true,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _AlignedAccessoryLayer extends StatelessWidget {
  const _AlignedAccessoryLayer({
    required this.path,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.filterQuality,
  });

  final String path;
  final double left;
  final double top;
  final double width;
  final double height;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Image.asset(
        path,
        fit: BoxFit.fill,
        filterQuality: filterQuality,
        isAntiAlias: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
