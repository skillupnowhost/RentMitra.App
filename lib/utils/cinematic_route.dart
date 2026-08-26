import 'package:flutter/material.dart';

/// Fade + gentle rise + scale-down transition used across the splash /
/// onboarding hand-offs, so moving between screens reads as one continuous
/// cinematic sequence instead of a platform-default slide cut. The incoming
/// page eases up into place from just below its resting position while
/// settling from a slight zoom, reading as an "arrival" rather than a flat
/// cross-fade.
///
/// Shared by [cinematicRoute] (imperative `Navigator` routes) and the
/// GoRouter `CustomTransitionPage`s in `core/router/app_router.dart`, so
/// both navigation paths render the identical motion.
Widget cinematicTransitionsBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.035),
        end: Offset.zero,
      ).animate(curved),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.045, end: 1.0).animate(curved),
        child: child,
      ),
    ),
  );
}

Route<T> cinematicRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 560),
    reverseTransitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: cinematicTransitionsBuilder,
  );
}
