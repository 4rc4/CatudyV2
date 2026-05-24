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
          if (accessoryPath == null && equippedItemId != null)
            _LegacyPetAccessoryOverlay(equippedItemId: equippedItemId!),
        ],
      ),
    );
  }
}

class _LegacyPetAccessoryOverlay extends StatelessWidget {
  const _LegacyPetAccessoryOverlay({required this.equippedItemId});

  final String equippedItemId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: switch (equippedItemId) {
            'violet_collar' => [
              Positioned(
                left: constraints.maxWidth * 0.35,
                top: constraints.maxHeight * 0.42,
                width: constraints.maxWidth * 0.30,
                height: constraints.maxHeight * 0.08,
                child: CustomPaint(
                  painter: _LegacyCollarPainter(color: const Color(0xFF7C68D8)),
                ),
              ),
            ],
            'sunny_hat' => [
              Positioned(
                left: constraints.maxWidth * 0.30,
                top: constraints.maxHeight * 0.02,
                width: constraints.maxWidth * 0.40,
                height: constraints.maxHeight * 0.18,
                child: CustomPaint(
                  painter: _LegacySunnyHatPainter(
                    color: const Color(0xFF45BDA8),
                  ),
                ),
              ),
            ],
            _ => const [],
          },
        );
      },
    );
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
