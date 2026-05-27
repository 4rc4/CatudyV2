import 'package:flutter/material.dart';

import '../../app/catudy_assets.dart';
import '../../app/catudy_pet_accessories.dart';

class CatudyPetAvatar extends StatelessWidget {
  const CatudyPetAvatar({
    super.key,
    this.equippedItemId,
    this.equippedItemIds,
    this.assetPath = CatudyAssets.mascot,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.high,
  });

  final String? equippedItemId;
  final List<String>? equippedItemIds;
  final String assetPath;
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
    final accessoryIds = _effectiveAccessoryIds();
    return SizedBox(
      width: width,
      height: height == null ? null : height! * _accessoryCanvasHeightRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxSize = constraints.biggest;
          if (!boxSize.width.isFinite || !boxSize.height.isFinite) {
            return Image.asset(
              assetPath,
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
                  assetPath,
                  fit: BoxFit.fill,
                  filterQuality: filterQuality,
                  isAntiAlias: true,
                ),
              ),
              for (final accessoryId in accessoryIds)
                _AccessoryLayer(
                  accessoryId: accessoryId,
                  canvasLeft: canvasLeft,
                  canvasTop: canvasTop,
                  canvasWidth: canvasSize.width,
                  canvasHeight: canvasSize.height,
                  scale: mascotScale,
                  filterQuality: filterQuality,
                ),
            ],
          );
        },
      ),
    );
  }

  List<String> _effectiveAccessoryIds() {
    final ids = <String>[];
    for (final id in equippedItemIds ?? const <String>[]) {
      if (id.isNotEmpty && !ids.contains(id)) {
        ids.add(id);
      }
    }
    final legacyId = equippedItemId;
    if (ids.isEmpty && legacyId != null && legacyId.isNotEmpty) {
      ids.add(legacyId);
    }
    return ids;
  }
}

class _AccessoryLayer extends StatelessWidget {
  const _AccessoryLayer({
    required this.accessoryId,
    required this.canvasLeft,
    required this.canvasTop,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.scale,
    required this.filterQuality,
  });

  final String accessoryId;
  final double canvasLeft;
  final double canvasTop;
  final double canvasWidth;
  final double canvasHeight;
  final double scale;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final accessory = CatudyPetAccessories.byId(accessoryId);
    final alignedPath = CatudyPetAccessories.alignedAssetPathFor(accessoryId);
    if (accessory != null && alignedPath != null) {
      return _AlignedAccessoryLayer(
        path: alignedPath,
        left: canvasLeft,
        top: canvasTop,
        width: canvasWidth,
        height: canvasHeight,
        filterQuality: filterQuality,
      );
    }
    final placement = CatudyPetAccessories.placementFor(accessoryId);
    final trimmedPath = CatudyPetAccessories.trimmedAssetPathFor(accessoryId);
    if (placement == null || trimmedPath == null) {
      return const SizedBox.shrink();
    }
    return _AnchoredAccessoryLayer(
      path: trimmedPath,
      placement: placement,
      canvasLeft: canvasLeft,
      canvasTop: canvasTop,
      scale: scale,
      filterQuality: filterQuality,
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
