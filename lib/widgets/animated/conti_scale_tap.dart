import 'package:flutter/material.dart';
import '../../core/constants/app_animation.dart';

class ContiScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ContiScaleTap({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<ContiScaleTap> createState() => _ContiScaleTapState();
}

class _ContiScaleTapState extends State<ContiScaleTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppAnimation.instant,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
