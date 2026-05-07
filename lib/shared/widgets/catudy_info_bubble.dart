import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/catudy_colors.dart';

class CatudyInfoTap extends StatelessWidget {
  const CatudyInfoTap({
    required this.title,
    required this.message,
    required this.child,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String message;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        CatudyInfoBubble.show(
          context,
          title: title,
          message: message,
          anchor: details.globalPosition,
        );
      },
      child: child,
    );
  }
}

class CatudyInfoBubble {
  const CatudyInfoBubble._();

  static OverlayEntry? _activeEntry;
  static ValueNotifier<bool>? _activeVisible;

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required Offset anchor,
  }) {
    _dismissActive();
    final overlay = Overlay.of(context);
    final route = ModalRoute.of(context);
    final visible = ValueNotifier<bool>(true);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        if (route != null && !route.isCurrent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _dismiss(visible, entry);
          });
          return const SizedBox.shrink();
        }
        return ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (context, isVisible, _) {
            return Positioned(
              left: _leftFor(context, anchor),
              top: _topFor(context, anchor),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                opacity: isVisible ? 1 : 0,
                child: _BubbleCard(
                  title: title,
                  message: message,
                  onClose: () => _dismiss(visible, entry),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    _activeEntry = entry;
    _activeVisible = visible;
  }

  static double _leftFor(BuildContext context, Offset anchor) {
    final width = MediaQuery.sizeOf(context).width;
    final maxLeft = math.max(14.0, width - 274);
    return (anchor.dx - 130).clamp(14, maxLeft).toDouble();
  }

  static double _topFor(BuildContext context, Offset anchor) {
    final height = MediaQuery.sizeOf(context).height;
    const bubbleEstimate = 172.0;
    const gap = 12.0;
    final maxTop = math.max(14.0, height - bubbleEstimate - 14);
    final preferredAbove = anchor.dy - bubbleEstimate - gap;
    if (preferredAbove >= 14) {
      return preferredAbove.clamp(14, maxTop).toDouble();
    }
    return (anchor.dy + gap).clamp(14, maxTop).toDouble();
  }

  static void _dismissActive() {
    final visible = _activeVisible;
    final entry = _activeEntry;
    if (visible == null || entry == null) {
      return;
    }
    _dismiss(visible, entry);
  }

  static void _dismiss(ValueNotifier<bool> visible, OverlayEntry entry) {
    if (!visible.value) {
      return;
    }
    visible.value = false;
    Future<void>.delayed(const Duration(milliseconds: 240), () {
      visible.dispose();
      if (entry.mounted) {
        entry.remove();
      }
      if (identical(_activeEntry, entry)) {
        _activeEntry = null;
        _activeVisible = null;
      }
    });
  }
}

class _BubbleCard extends StatelessWidget {
  const _BubbleCard({
    required this.title,
    required this.message,
    required this.onClose,
  });

  final String title;
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final dark = CatudyColors.isDark(context);
    final background = dark
        ? CatudyColors.darkSurface.withValues(alpha: 0.86)
        : Colors.white.withValues(alpha: 0.82);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CatudyColors.teal.withValues(alpha: 0.26)),
          boxShadow: [
            BoxShadow(
              color: (dark ? Colors.black : CatudyColors.violet).withValues(
                alpha: dark ? 0.26 : 0.12,
              ),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_rounded,
                  size: 18,
                  color: CatudyColors.teal,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: CatudyColors.blueFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: CatudyColors.mutedFor(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                color: CatudyColors.mutedFor(context),
                height: 1.28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
