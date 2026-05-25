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
              if (placement != null &&
                  placement.useAlignedCanvas &&
                  alignedPath != null)
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
                )
              else if (accessory != null && alignedPath != null)
                _AlignedAccessoryLayer(
                  path: alignedPath,
                  left: canvasLeft,
                  top: canvasTop,
                  width: canvasSize.width,
                  height: canvasSize.height,
                  filterQuality: filterQuality,
                ),
              if (accessory == null && equippedItemId != null)
                _LegacyPetAccessoryOverlay(
                  equippedItemId: equippedItemId!,
                  canvasLeft: canvasLeft,
                  canvasTop: canvasTop,
                  scale: mascotScale,
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

class _LegacyPetAccessoryOverlay extends StatelessWidget {
  const _LegacyPetAccessoryOverlay({
    required this.equippedItemId,
    required this.canvasLeft,
    required this.canvasTop,
    required this.scale,
  });

  final String equippedItemId;
  final double canvasLeft;
  final double canvasTop;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return switch (equippedItemId) {
      'violet_collar' => Positioned(
        left: canvasLeft + 108 * scale,
        top: canvasTop + (CatudyPetAvatar._accessoryTopOverflow + 245) * scale,
        width: 95 * scale,
        height: 38 * scale,
        child: CustomPaint(
          painter: _LegacyCollarPainter(color: const Color(0xFF7C68D8)),
        ),
      ),
      'sunny_hat' => Positioned(
        left: canvasLeft + 92 * scale,
        top: canvasTop + (CatudyPetAvatar._accessoryTopOverflow + 40) * scale,
        width: 126 * scale,
        height: 74 * scale,
        child: CustomPaint(
          painter: _LegacySunnyHatPainter(color: const Color(0xFF45BDA8)),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _LegacyCollarPainter extends CustomPainter {
  const _LegacyCollarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = const Color(0xFF5D4AAE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * 0.12
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.18,
      size.width * 0.84,
      size.height * 0.54,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.height)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.height)),
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.82),
      size.height * 0.18,
      Paint()..color = const Color(0xFFFFD65A),
    );
  }

  @override
  bool shouldRepaint(covariant _LegacyCollarPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LegacySunnyHatPainter extends CustomPainter {
  const _LegacySunnyHatPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final brim = Paint()..color = color;
    final dome = Paint()..color = color.withValues(alpha: 0.92);
    final outline = Paint()
      ..color = const Color(0xFF5B5376)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round;

    final domeRect = Rect.fromLTWH(
      size.width * 0.22,
      size.height * 0.10,
      size.width * 0.56,
      size.height * 0.58,
    );
    canvas.drawArc(domeRect, 3.14, 3.14, false, outline);
    canvas.drawOval(domeRect, dome);
    canvas.drawOval(domeRect, outline);

    final brimPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.82,
        size.width * 0.92,
        size.height * 0.62,
      )
      ..lineTo(size.width * 0.82, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.98,
        size.width * 0.18,
        size.height * 0.82,
      )
      ..close();
    canvas.drawPath(brimPath, brim);
    canvas.drawPath(brimPath, outline);
  }

  @override
  bool shouldRepaint(covariant _LegacySunnyHatPainter oldDelegate) =>
      oldDelegate.color != color;
}
