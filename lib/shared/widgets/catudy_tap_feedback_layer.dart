import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/theme/catudy_colors.dart';

class CatudyTapFeedbackLayer extends StatefulWidget {
  const CatudyTapFeedbackLayer({required this.child, super.key});

  final Widget child;

  @override
  State<CatudyTapFeedbackLayer> createState() => _CatudyTapFeedbackLayerState();
}

class _CatudyTapFeedbackLayerState extends State<CatudyTapFeedbackLayer>
    with TickerProviderStateMixin {
  final _pulses = <_TapPulse>[];

  @override
  void dispose() {
    for (final pulse in _pulses) {
      pulse.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_pulses.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TapPulsePainter(
                    pulses: List<_TapPulse>.unmodifiable(_pulses),
                    dark: Theme.of(context).brightness == Brightness.dark,
                    repaint: Listenable.merge(
                      _pulses.map((pulse) => pulse.controller).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons != kPrimaryMouseButton) {
      return;
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) {
      return;
    }
    final pulse = _TapPulse(
      position: renderObject.globalToLocal(event.position),
      controller: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      ),
    );
    pulse.controller.addStatusListener((status) {
      if (status != AnimationStatus.completed) {
        return;
      }
      if (!mounted) {
        pulse.controller.dispose();
        return;
      }
      setState(() => _pulses.remove(pulse));
      pulse.controller.dispose();
    });
    setState(() => _pulses.add(pulse));
    pulse.controller.forward();
  }
}

class _TapPulse {
  _TapPulse({required this.position, required this.controller});

  final Offset position;
  final AnimationController controller;
}

class _TapPulsePainter extends CustomPainter {
  _TapPulsePainter({
    required this.pulses,
    required this.dark,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<_TapPulse> pulses;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    for (final pulse in pulses) {
      final value = Curves.easeOutCubic.transform(pulse.controller.value);
      final radius = ui.lerpDouble(8, 34, value)!;
      final alpha = (1 - value).clamp(0.0, 1.0);
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ui.lerpDouble(3.2, 1.0, value)!
        ..color = (dark ? CatudyColors.teal : CatudyColors.violet).withValues(
          alpha: alpha * 0.34,
        );
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = CatudyColors.yellow.withValues(alpha: alpha * 0.18);

      canvas.drawCircle(pulse.position, radius * 0.45, glowPaint);
      canvas.drawCircle(pulse.position, radius, ringPaint);

      final sparklePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = CatudyColors.coral.withValues(alpha: alpha * 0.42);
      for (var index = 0; index < 4; index += 1) {
        final angle = (math.pi / 2) * index + value * 0.8;
        final offset = Offset(math.cos(angle), math.sin(angle)) * radius * 0.8;
        canvas.drawCircle(
          pulse.position + offset,
          ui.lerpDouble(2.8, 0.8, value)!,
          sparklePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TapPulsePainter oldDelegate) {
    return oldDelegate.pulses != pulses || oldDelegate.dark != dark;
  }
}
