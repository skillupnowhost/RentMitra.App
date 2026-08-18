import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Three purpose-built icon animations for the "Free Delivery / Free
/// Installation / Service & Maintenance" benefits row — each motion mimics
/// what that service actually looks like (a truck rolling, a technician
/// tightening a bolt, a gear + wrench servicing) rather than all three
/// sharing one generic pulse.
///
/// A delivery truck that drives smoothly on the spot, leaving a short fading
/// motion trail and a light suspension bounce, so it reads as "en route"
/// rather than a static glyph.
class DeliveryTruckIcon extends StatefulWidget {
  const DeliveryTruckIcon({
    super.key,
    this.size = 20,
    this.color = AppColors.purple,
    this.startDelay = Duration.zero,
  });

  final double size;
  final Color color;
  final Duration startDelay;

  @override
  State<DeliveryTruckIcon> createState() => _DeliveryTruckIconState();
}

class _DeliveryTruckIconState extends State<DeliveryTruckIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drive = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _startTimer = Timer(widget.startDelay, () {
      if (mounted) _drive.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _drive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _drive, curve: Curves.easeInOut);
    return SizedBox(
      width: widget.size * 1.3,
      height: widget.size,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          final t = curved.value;
          final dx = (t - 0.5) * widget.size * 0.5;
          final bounce = (t < 0.5 ? t : 1 - t) * widget.size * 0.08;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: widget.size * 0.02,
                child: Opacity(
                  opacity: (0.45 - t * 0.4).clamp(0.0, 0.45),
                  child: Container(
                    width: widget.size * 0.3,
                    height: 2,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(dx, -bounce),
                child: Icon(
                  Icons.local_shipping_rounded,
                  size: widget.size,
                  color: widget.color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A technician's wrench tightening a bolt on the appliance — the base
/// service glyph stays put while the wrench pivots back and forth with a
/// small synced squeeze, mimicking an actual installation motion.
class InstallationIcon extends StatefulWidget {
  const InstallationIcon({
    super.key,
    this.size = 20,
    this.color = AppColors.purple,
    this.startDelay = Duration.zero,
  });

  final double size;
  final Color color;
  final Duration startDelay;

  @override
  State<InstallationIcon> createState() => _InstallationIconState();
}

class _InstallationIconState extends State<InstallationIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _startTimer = Timer(widget.startDelay, () {
      if (mounted) _turn.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _turn, curve: Curves.easeInOut);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          final t = curved.value;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.home_repair_service_rounded,
                size: widget.size,
                color: widget.color,
              ),
              Positioned(
                right: -widget.size * 0.08,
                bottom: -widget.size * 0.06,
                child: Transform.rotate(
                  angle: (t - 0.5) * 0.85,
                  child: Transform.scale(
                    scale: 0.94 + t * 0.1,
                    child: Icon(
                      Icons.build_rounded,
                      size: widget.size * 0.52,
                      color: widget.color,
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

/// A service gear turning continuously with a wrench nudging back and forth
/// against it — reads as active maintenance rather than a still badge.
class MaintenanceIcon extends StatefulWidget {
  const MaintenanceIcon({
    super.key,
    this.size = 20,
    this.color = AppColors.purple,
    this.startDelay = Duration.zero,
  });

  final double size;
  final Color color;
  final Duration startDelay;

  @override
  State<MaintenanceIcon> createState() => _MaintenanceIconState();
}

class _MaintenanceIconState extends State<MaintenanceIcon>
    with TickerProviderStateMixin {
  late final AnimationController _gear = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _wrench = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _startTimer = Timer(widget.startDelay, () {
      if (!mounted) return;
      _gear.repeat();
      _wrench.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _gear.dispose();
    _wrench.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wrenchCurve = CurvedAnimation(
      parent: _wrench,
      curve: Curves.easeInOut,
    );
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          RotationTransition(
            turns: _gear,
            child: Icon(
              Icons.settings_rounded,
              size: widget.size,
              color: widget.color,
            ),
          ),
          Positioned(
            left: -widget.size * 0.1,
            bottom: -widget.size * 0.08,
            child: AnimatedBuilder(
              animation: wrenchCurve,
              builder: (context, child) => Transform.rotate(
                angle: (wrenchCurve.value - 0.5) * 0.5,
                child: child,
              ),
              child: Icon(
                Icons.build_rounded,
                size: widget.size * 0.46,
                color: widget.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
