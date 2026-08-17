import 'package:flutter/material.dart';

/// Real product/illustration photography exported from the Figma file,
/// replacing the earlier hand-drawn vector placeholders.
class ApplianceClusterImage extends StatelessWidget {
  const ApplianceClusterImage({super.key, this.width = 220});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/appliance_cluster.png',
      width: width,
      fit: BoxFit.contain,
    );
  }
}

class AcProductImage extends StatelessWidget {
  const AcProductImage({super.key, this.width = 100});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/ac_product.png',
      width: width,
      fit: BoxFit.contain,
    );
  }
}

class FridgeProductImage extends StatelessWidget {
  const FridgeProductImage({super.key, this.width = 60});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/fridge_product.png',
      width: width,
      fit: BoxFit.contain,
    );
  }
}

class WasherProductImage extends StatelessWidget {
  const WasherProductImage({super.key, this.width = 70});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/washer_product.png',
      width: width,
      fit: BoxFit.contain,
    );
  }
}
