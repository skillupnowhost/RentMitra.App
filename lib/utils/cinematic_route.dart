import 'package:flutter/material.dart';

/// Fade + gentle scale-down page transition used across the splash /
/// onboarding hand-offs, so moving between screens reads as one continuous
/// cinematic sequence instead of a platform-default slide cut.
Route<T> cinematicRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 620),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.06, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
