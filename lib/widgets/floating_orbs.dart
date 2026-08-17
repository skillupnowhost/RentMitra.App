import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class _OrbSpec {
  const _OrbSpec({
    required this.alignment,
    required this.size,
    required this.color,
    required this.driftX,
    required this.driftY,
    required this.speed,
    required this.phase,
  });

  final Alignment alignment;
  final double size;
  final Color color;
  final double driftX;
  final double driftY;
  final double speed;
  final double phase;
}

const _specs = [
  _OrbSpec(
    alignment: Alignment(-0.92, -0.82),
    size: 150,
    color: AppColors.purple,
    driftX: 16,
    driftY: 20,
    speed: 0.55,
    phase: 0.05,
  ),
  _OrbSpec(
    alignment: Alignment(0.95, -0.55),
    size: 100,
    color: AppColors.purpleSoft,
    driftX: 12,
    driftY: 16,
    speed: 0.8,
    phase: 0.4,
  ),
  _OrbSpec(
    alignment: Alignment(0.88, 0.92),
    size: 180,
    color: AppColors.ctaPurple,
    driftX: 18,
    driftY: 16,
    speed: 0.45,
    phase: 0.7,
  ),
  _OrbSpec(
    alignment: Alignment(-0.85, 0.78),
    size: 120,
    color: AppColors.purple,
    driftX: 14,
    driftY: 18,
    speed: 0.65,
    phase: 0.2,
  ),
];

/// Soft glowing spheres that drift slowly behind the foreground content —
/// pure decoration, [IgnorePointer]'d and clipped to the enclosing [Stack]
/// (its default `Clip.hardEdge`) so it can never affect layout or hit
/// testing on the screens that host it.
class FloatingOrbsBackground extends StatefulWidget {
  const FloatingOrbsBackground({super.key, this.intensity = 1.0});

  final double intensity;

  @override
  State<FloatingOrbsBackground> createState() => _FloatingOrbsBackgroundState();
}

class _FloatingOrbsBackgroundState extends State<FloatingOrbsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            children: [
              for (final spec in _specs)
                Align(
                  alignment: spec.alignment,
                  child: Transform.translate(
                    offset: Offset(
                      math.sin((t + spec.phase) * 2 * math.pi * spec.speed) *
                          spec.driftX,
                      math.cos((t + spec.phase) * 2 * math.pi * spec.speed) *
                          spec.driftY,
                    ),
                    child: Container(
                      width: spec.size,
                      height: spec.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            spec.color.withValues(
                              alpha: 0.30 * widget.intensity,
                            ),
                            spec.color.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
