import 'package:flutter/material.dart';

/// Real product/illustration photography exported from the Figma file,
/// replacing the earlier hand-drawn vector placeholders.
///
/// Each image is bounded to a [width] x [height] box (default height is a
/// portrait-friendly 1.3x the width) via [BoxFit.contain] rather than being
/// given only a width — the source photos are tightly cropped to each
/// appliance's silhouette, so a portrait shape like the fridge would
/// otherwise inherit its full (very tall) native aspect ratio and blow out
/// whatever card or slide it sits in.
class ApplianceClusterImage extends StatelessWidget {
  const ApplianceClusterImage({super.key, this.width = 220, double? height})
    : height = height ?? width * 1.3;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: height),
      child: Image.asset(
        'assets/images/appliance_cluster.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class AcProductImage extends StatelessWidget {
  const AcProductImage({super.key, this.width = 100, double? height})
    : height = height ?? width * 1.3;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: height),
      child: Image.asset('assets/images/ac_product.png', fit: BoxFit.contain),
    );
  }
}

class FridgeDoubleDoorProductImage extends StatelessWidget {
  const FridgeDoubleDoorProductImage({super.key, this.width = 60, double? height})
    : height = height ?? width * 1.3;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: height),
      child: Image.asset(
        'assets/images/Double door fridge.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class FridgeDoubleDoorHeaderImage extends StatelessWidget {
  const FridgeDoubleDoorHeaderImage({super.key, this.width = 95, double? height})
    : height = height ?? width * 1.3;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: height),
      child: Image.asset(
        'assets/images/Double door fridge (header).png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class WasherProductImage extends StatelessWidget {
  const WasherProductImage({super.key, this.width = 70, double? height})
    : height = height ?? width * 1.3;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: height),
      child: Image.asset(
        'assets/images/washer_product.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class FridgeSingleDoorProductImage extends StatelessWidget {
  const FridgeSingleDoorProductImage({
    super.key,
    this.width = 60,
    double? height,
  }) : height = height ?? width * 1.3;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: height),
      child: Image.asset(
        'assets/images/fridge_single_door_product.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class WasherTopLoadProductImage extends StatelessWidget {
  const WasherTopLoadProductImage({super.key, this.width = 70, double? height})
    : height = height ?? width * 1.3;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: height),
      child: Image.asset(
        'assets/images/washer_top_load_product.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class WasherTopLoadImage extends StatelessWidget {
  const WasherTopLoadImage({super.key, this.width = 70, double? height})
    : height = height ?? width * 1.3;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: height),
      child: Image.asset(
        'assets/images/Washing machine (header).png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class WasherFrontLoadImage extends StatelessWidget {
  const WasherFrontLoadImage({super.key, this.width = 70, double? height})
    : height = height ?? width * 1.3;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width, maxHeight: height),
      child: Image.asset(
        'assets/images/Washing machine  2.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
