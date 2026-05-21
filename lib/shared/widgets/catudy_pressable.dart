import 'package:flutter/material.dart';

class CatudyPressable extends StatefulWidget {
  const CatudyPressable({
    required this.child,
    this.enabled = true,
    this.scale = 0.985,
    this.duration = const Duration(milliseconds: 110),
    super.key,
  });

  final Widget child;
  final bool enabled;
  final double scale;
  final Duration duration;

  @override
  State<CatudyPressable> createState() => _CatudyPressableState();
}

class _CatudyPressableState extends State<CatudyPressable> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (!widget.enabled || _pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        duration: widget.duration,
        curve: Curves.easeOut,
        scale: _pressed ? widget.scale : 1,
        child: widget.child,
      ),
    );
  }
}
