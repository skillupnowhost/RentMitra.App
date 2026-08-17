import 'package:flutter/material.dart';

/// Renders a slide's product image. The source PNGs are full marketing
/// compositions exported from Figma — pedestal, props and lighting already
/// baked in — so no synthetic shadow/depth layer is added here; entrance and
/// cross-slide motion are handled by the caller (`FadeSlideIn` for the
/// one-time reveal, the page-transform parallax for swipe transitions).
class FloatingProductArt extends StatelessWidget {
  const FloatingProductArt({
    super.key,
    required this.assetPath,
    required this.width,
  });

  final String assetPath;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetPath, width: width, fit: BoxFit.contain);
  }
}
