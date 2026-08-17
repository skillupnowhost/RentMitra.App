import 'package:flutter/material.dart';

/// Wraps a product image with a slow, perpetual "alive" idle motion — a
/// gentle vertical bob plus a barely-there breathing scale — so the hero
/// product art never sits perfectly still. Purely a paint-time transform
/// (translate + scale) driven by one repeating [AnimationController], so it
/// stays cheap regardless of image size.
class FloatingProductArt extends StatefulWidget {
  const FloatingProductArt({
    super.key,
    required this.assetPath,
    required this.width,
    this.bobAmount = 8,
    this.breatheAmount = 0.025,
    this.period = const Duration(seconds: 5),
  });

  final String assetPath;
  final double width;
  final double bobAmount;
  final double breatheAmount;
  final Duration period;

  @override
  State<FloatingProductArt> createState() => _FloatingProductArtState();
}

class _FloatingProductArtState extends State<FloatingProductArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value - 0.5; // -0.5 .. 0.5
        return Transform.translate(
          offset: Offset(0, t * widget.bobAmount),
          child: Transform.scale(
            scale: 1.0 + t * widget.breatheAmount,
            child: child,
          ),
        );
      },
      child: Image.asset(
        widget.assetPath,
        width: widget.width,
        fit: BoxFit.contain,
      ),
    );
  }
}
