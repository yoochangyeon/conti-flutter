import 'package:flutter/material.dart';
import '../../core/constants/app_animation.dart';

class ContiFadeIn extends StatefulWidget {
  final Widget child;
  final bool slideUp;
  final Duration duration;
  final Duration delay;

  const ContiFadeIn({
    super.key,
    required this.child,
    this.slideUp = true,
    this.duration = AppAnimation.normal,
    this.delay = Duration.zero,
  });

  @override
  State<ContiFadeIn> createState() => _ContiFadeInState();
}

class _ContiFadeInState extends State<ContiFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: AppAnimation.decelerate,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimation.decelerate,
    ));
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slideUp) {
      return FadeTransition(
        opacity: _opacity,
        child: AnimatedBuilder(
          animation: _slide,
          builder: (context, child) => Transform.translate(
            offset: _slide.value,
            child: child,
          ),
          child: widget.child,
        ),
      );
    }
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
