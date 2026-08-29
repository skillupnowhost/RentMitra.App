
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/order_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/appliance_art.dart';
import 'checkout_screen.dart';

class RentalConfirmationScreen extends StatefulWidget {
  const RentalConfirmationScreen({
    super.key,
    required this.product,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.houseFlatNumber,
    required this.apartmentName,
    required this.streetArea,
    required this.landmark,
    required this.city,
    required this.pincode,
    required this.orderId,
    required this.razorpayPaymentId,
  });

  final CheckoutProduct product;

  final String fullName;
  final String mobile;
  final String email;

  final String houseFlatNumber;
  final String apartmentName;
  final String streetArea;
  final String landmark;
  final String city;
  final String pincode;

  final int orderId;
  final String razorpayPaymentId;

  @override
  State<RentalConfirmationScreen> createState() =>
      _RentalConfirmationScreenState();
}

class _RentalConfirmationScreenState
    extends State<RentalConfirmationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _particleController;
  late final AnimationController _tickController;

  late final Animation<double> _tickScale;
  late final Animation<double> _tickGlow;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // FALLING PARTICLE ANIMATION
    // ============================================================

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 3600,
      ),
    )..repeat();

    // ============================================================
    // TICK ANIMATION
    // ============================================================

    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    );

    _tickScale = CurvedAnimation(
      parent: _tickController,
      curve: Curves.elasticOut,
    );

    _tickGlow = CurvedAnimation(
      parent: _tickController,
      curve: Curves.easeOut,
    );

    _tickController.forward();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _tickController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final contentWidth = width > 520 ? 520.0 : width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentWidth,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppTextStyles.fig(16),
                AppTextStyles.fig(14),
                AppTextStyles.fig(16),
                AppTextStyles.fig(20),
              ),
              child: Column(
                children: [
                  // ==================================================
                  // SUCCESS HEADER
                  // ==================================================

                  _buildSuccessHeader(),

                  SizedBox(
                    height: AppTextStyles.fig(24),
                  ),

                  // ==================================================
                  // ORDER SUMMARY
                  // ==================================================

                  _buildOrderSummary(),

                  SizedBox(
                    height: AppTextStyles.fig(14),
                  ),

                  // ==================================================
                  // WHAT'S NEXT
                  // ==================================================

                  _buildWhatsNext(),

                  SizedBox(
                    height: AppTextStyles.fig(14),
                  ),

                  // ==================================================
                  // SERVICE BENEFITS
                  // ==================================================

                  _buildServiceBenefits(),

                  SizedBox(
                    height: AppTextStyles.fig(20),
                  ),

                  // ==================================================
                  // CONTINUE
                  // ==================================================

                  _buildContinueButton(context),

                  SizedBox(
                    height: AppTextStyles.fig(6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUCCESS HEADER
  // ============================================================

  Widget _buildSuccessHeader() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: AppTextStyles.fig(180),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _particleController,
                _tickController,
              ]),
              builder: (context, child) {
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 8,
                      delay: 0.00,
                      size: 7,
                      color: Colors.amber,
                      shape: ParticleShape.circle,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 35,
                      delay: 0.19,
                      size: 8,
                      color: AppColors.purple,
                      shape: ParticleShape.diamond,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 67,
                      delay: 0.42,
                      size: 6,
                      color: Colors.green,
                      shape: ParticleShape.circle,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 96,
                      delay: 0.08,
                      size: 8,
                      color: Colors.amber,
                      shape: ParticleShape.diamond,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 125,
                      delay: 0.55,
                      size: 7,
                      color: AppColors.purple,
                      shape: ParticleShape.circle,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 153,
                      delay: 0.28,
                      size: 9,
                      color: Colors.green.shade400,
                      shape: ParticleShape.diamond,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 184,
                      delay: 0.67,
                      size: 6,
                      color: Colors.amber,
                      shape: ParticleShape.circle,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 212,
                      delay: 0.35,
                      size: 8,
                      color: AppColors.purple,
                      shape: ParticleShape.diamond,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 243,
                      delay: 0.74,
                      size: 7,
                      color: Colors.green,
                      shape: ParticleShape.circle,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 272,
                      delay: 0.14,
                      size: 8,
                      color: Colors.amber,
                      shape: ParticleShape.diamond,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 301,
                      delay: 0.48,
                      size: 6,
                      color: AppColors.purple,
                      shape: ParticleShape.circle,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 330,
                      delay: 0.63,
                      size: 8,
                      color: Colors.green.shade400,
                      shape: ParticleShape.diamond,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 358,
                      delay: 0.22,
                      size: 7,
                      color: Colors.amber,
                      shape: ParticleShape.circle,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 389,
                      delay: 0.58,
                      size: 8,
                      color: AppColors.purple,
                      shape: ParticleShape.diamond,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 420,
                      delay: 0.04,
                      size: 6,
                      color: Colors.green,
                      shape: ParticleShape.circle,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 452,
                      delay: 0.39,
                      size: 8,
                      color: Colors.amber,
                      shape: ParticleShape.diamond,
                    ),
                    _fallingParticle(
                      progress: _particleController.value,
                      startX: 480,
                      delay: 0.71,
                      size: 7,
                      color: AppColors.purple,
                      shape: ParticleShape.circle,
                    ),

                    // ==================================================
                    // TICK MARK
                    // ==================================================

                    Center(
                      child: AnimatedBuilder(
                        animation: _tickController,
                        builder: (context, child) {
                          final scale =
                              0.60 + (_tickScale.value * 0.40);

                          final glow =
                              0.08 + (_tickGlow.value * 0.16);

                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: AppTextStyles.fig(92),
                              height: AppTextStyles.fig(92),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(
                                      alpha: glow,
                                    ),
                                    blurRadius: 22,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(
                                AppTextStyles.fig(7),
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                                alignment: Alignment.center,
                                child: Transform.scale(
                                  scale: _tickScale.value
                                      .clamp(0.0, 1.0),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: AppTextStyles.fig(55),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Text(
            'Rental Confirmed!',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 27,
              weight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),

          SizedBox(
            height: AppTextStyles.fig(6),
          ),

          Text(
            'Your rental request has been successfully placed.',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(
              figmaSize: 14,
              weight: FontWeight.w400,
              color: AppColors.textGray,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FALLING PARTICLE
  // ============================================================

  Widget _fallingParticle({
    required double progress,
    required double startX,
    required double delay,
    required double size,
    required Color color,
    required ParticleShape shape,
  }) {
    final adjustedProgress =
        (progress + delay) % 1.0;

    final availableHeight =
        AppTextStyles.fig(220);

    final top =
        -AppTextStyles.fig(30) +
        adjustedProgress * availableHeight;

    final horizontalMovement =
        math.sin(
              adjustedProgress * math.pi * 2,
            ) *
            AppTextStyles.fig(8);

    final rotation =
        adjustedProgress * math.pi * 4;

    double opacity = 1.0;

    if (adjustedProgress < 0.12) {
      opacity =
          adjustedProgress / 0.12;
    } else if (adjustedProgress > 0.85) {
      opacity =
          (1.0 - adjustedProgress) / 0.15;
    }

    return Positioned(
      left:
          AppTextStyles.fig(startX) +
          horizontalMovement,
      top: top,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: rotation,
          child: _particleShape(
            size: size,
            color: color,
            shape: shape,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PARTICLE SHAPE
  // ============================================================

  Widget _particleShape({
    required double size,
    required Color color,
    required ParticleShape shape,
  }) {
    switch (shape) {
      case ParticleShape.circle:
        return Container(
          width: AppTextStyles.fig(size),
          height: AppTextStyles.fig(size),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(
              alpha: 0.72,
            ),
          ),
        );

      case ParticleShape.diamond:
        return Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: AppTextStyles.fig(size),
            height: AppTextStyles.fig(size),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.72,
              ),
              borderRadius:
                  BorderRadius.circular(2),
            ),
          ),
        );
    }
  }

  // ============================================================
  // ORDER SUMMARY
  // ============================================================

  Widget _buildOrderSummary() {
    final product = widget.product;

    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.assignment_outlined,
            title: 'Order Summary',
          ),

          SizedBox(
            height: AppTextStyles.fig(14),
          ),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              AppTextStyles.fig(12),
            ),
            decoration: BoxDecoration(
              color: AppColors.bgCardPurple,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: AppTextStyles.fig(92),
                  height: AppTextStyles.fig(82),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(11),
                    border: Border.all(
                      color: AppColors.divider,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _buildProductImage(
                    product,
                  ),
                ),

                SizedBox(
                  width: AppTextStyles.fig(14),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Product',
                        style: AppTextStyles.of(
                          figmaSize: 13,
                          weight:
                              FontWeight.w400,
                          color:
                              AppColors.textGray,
                        ),
                      ),

                      SizedBox(
                        height:
                            AppTextStyles.fig(5),
                      ),

                      Text(
                        product.name,
                        maxLines: 3,
                        overflow:
                            TextOverflow.ellipsis,
                        style: AppTextStyles.of(
                          figmaSize: 16,
                          weight:
                              FontWeight.w700,
                          color: AppColors.navy,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: AppTextStyles.fig(16),
          ),

          if (product.isCombo) ...[
            _priceRow(
              'Monthly Rental',
              product.monthlyRent,
            ),

            _dashedDivider(),

            _priceRow(
              'Combo Discount',
              -product.discount,
              valueColor:
                  Colors.green.shade700,
                  titleColor: Colors.green.shade700,
            ),

            _dashedDivider(),

            _priceRow(
              'Monthly Rent After Discount',
              product.afterDiscount,
            ),

            _dashedDivider(),

            _priceRow(
              'GST (18%)',
              product.gst,
            ),
          ] else ...[
            _priceRow(
              'Monthly Rental',
              product.monthlyRent,
            ),

            _dashedDivider(),

            _priceRow(
              'GST (18%)',
              product.gst,
            ),
          ],

          Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTextStyles.fig(14),
            ),
            child: Container(
              height: 1,
              color: AppColors.divider,
            ),
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Monthly Amount',
                  style: AppTextStyles.of(
                    figmaSize: 16,
                    weight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),

              Text(
                _money(product.total),
                style: AppTextStyles.of(
                  figmaSize: 22,
                  weight: FontWeight.w800,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTextStyles.fig(14),
            ),
            child: Container(
              height: 1,
              color: AppColors.divider,
            ),
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Payment Status',
                  style: AppTextStyles.of(
                    figmaSize: 14,
                    weight: FontWeight.w400,
                    color: AppColors.navy,
                  ),
                ),
              ),

              Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    'Paid Successfully',
                    style: AppTextStyles.of(
                      figmaSize: 14,
                      weight: FontWeight.w700,
                      color:
                          Colors.green.shade600,
                    ),
                  ),

                  SizedBox(
                    width:
                        AppTextStyles.fig(7),
                  ),

                  Icon(
                    Icons.check_circle_outline,
                    color:
                        Colors.green.shade600,
                    size: 23,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT IMAGE
  // ============================================================

  Widget _buildProductImage(
    CheckoutProduct product,
  ) {
    if (product.isCombo) {
      return const ApplianceClusterImage(
        width: 70,
        height: 70,
      );
    }

    final name =
        product.name.toLowerCase();

    if (name.contains('ac') ||
        name.contains('air conditioner')) {
      return const AcProductImage(
        width: 82,
        height: 70,
      );
    }

    if (name.contains('refrigerator') ||
        name.contains('fridge')) {
      return name.contains('double')
          ? const FridgeDoubleDoorProductImage(
              width: 48,
              height: 70,
            )
          : const FridgeSingleDoorProductImage(
              width: 48,
              height: 70,
            );
    }

    if (name.contains('washing') ||
        name.contains('washer')) {
      return const WasherProductImage(
        width: 55,
        height: 70,
      );
    }

    return Icon(
      Icons.home_repair_service_outlined,
      color: AppColors.purple,
      size: AppTextStyles.fig(45),
    );
  }

  // ============================================================
  // WHAT'S NEXT
  // ============================================================

  Widget _buildWhatsNext() {
    final steps = [
      (
        number: '1',
        icon: Icons.fact_check_outlined,
        title: 'Verification &\nOrder Review',
      ),
      (
        number: '2',
        icon: Icons.groups_outlined,
        title: 'Delivery Team\nAssignment',
      ),
      (
        number: '3',
        icon: Icons.calendar_month_outlined,
        title: 'Installation\nScheduling',
      ),
      (
        number: '4',
        icon: Icons.local_shipping_outlined,
        title: 'Appliance\nDelivery',
      ),
    ];

    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.calendar_month_outlined,
            title: 'What’s Next?',
          ),

          SizedBox(
            height: AppTextStyles.fig(24),
          ),

          LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              final itemWidth =
                  constraints.maxWidth /
                  steps.length;

              final circleSize =
                  AppTextStyles.fig(34);

              return SizedBox(
                height:
                    AppTextStyles.fig(155),
                child: Stack(
                  children: [
                    for (
                      int i = 0;
                      i < steps.length - 1;
                      i++
                    )
                      Positioned(
                        left:
                            itemWidth * i +
                            (itemWidth / 2) +
                            (circleSize / 2),
                        width:
                            itemWidth -
                            circleSize,
                        top:
                            circleSize / 2,
                        child:
                            _dottedConnector(),
                      ),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children:
                          List.generate(
                        steps.length,
                        (index) {
                          final step =
                              steps[index];

                          return SizedBox(
                            width:
                                itemWidth,
                            child: Column(
                              children: [
                                Container(
                                  width:
                                      circleSize,
                                  height:
                                      circleSize,
                                  decoration:
                                      BoxDecoration(
                                    shape:
                                        BoxShape
                                            .circle,
                                    color: AppColors
                                        .purple
                                        .withValues(
                                      alpha: 0.88,
                                    ),
                                  ),
                                  alignment:
                                      Alignment
                                          .center,
                                  child: Text(
                                    step.number,
                                    textAlign:
                                        TextAlign
                                            .center,
                                    style:
                                        AppTextStyles
                                            .of(
                                      figmaSize:
                                          14,
                                      weight:
                                          FontWeight
                                              .w700,
                                      color:
                                          Colors
                                              .white,
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height:
                                      AppTextStyles
                                          .fig(13),
                                ),

                                Icon(
                                  step.icon,
                                  color:
                                      AppColors
                                          .purple,
                                  size:
                                      AppTextStyles
                                          .fig(29),
                                ),

                                SizedBox(
                                  height:
                                      AppTextStyles
                                          .fig(8),
                                ),

                                SizedBox(
                                  width:
                                      AppTextStyles
                                          .fig(82),
                                  child: Text(
                                    step.title,
                                    textAlign:
                                        TextAlign
                                            .center,
                                    style:
                                        AppTextStyles
                                            .of(
                                      figmaSize:
                                          10.5,
                                      weight:
                                          FontWeight
                                              .w500,
                                      color:
                                          AppColors
                                              .navy,
                                      height:
                                          1.30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOTTED CONNECTOR
  // ============================================================

  Widget _dottedConnector() {
    return CustomPaint(
      painter: _DashedLinePainter(
        color:
            AppColors.purple.withValues(
          alpha: 0.50,
        ),
      ),
      child: const SizedBox(
        width: double.infinity,
        height: 1,
      ),
    );
  }

  // ============================================================
  // SERVICE BENEFITS
  // ============================================================

  Widget _buildServiceBenefits() {
    final benefits = [
      (
        icon:
            Icons.local_shipping_outlined,
        title: 'Free\nDelivery',
      ),
      (
        icon:
            Icons.construction_outlined,
        title: 'Free\nInstallation',
      ),
      (
        icon:
            Icons.verified_user_outlined,
        title:
            'Service &\nMaintenance\nIncluded',
      ),
      (
        icon:
            Icons.headset_mic_outlined,
        title:
            'Dedicated\nSupport',
      ),
    ];

    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.shield_outlined,
            title: 'Service Benefits',
          ),

          SizedBox(
            height: AppTextStyles.fig(20),
          ),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children:
                List.generate(
              benefits.length,
              (index) {
                final benefit =
                    benefits[index];

                return Expanded(
                  child: Container(
                    decoration:
                        BoxDecoration(
                      border: index == 0
                          ? null
                          : Border(
                              left:
                                  BorderSide(
                                color:
                                    AppColors
                                        .divider,
                              ),
                            ),
                    ),
                    padding:
                        EdgeInsets.symmetric(
                      horizontal:
                          AppTextStyles.fig(6),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          benefit.icon,
                          color:
                              AppColors.purple,
                          size:
                              AppTextStyles.fig(
                            29,
                          ),
                        ),

                        SizedBox(
                          height:
                              AppTextStyles.fig(
                            8,
                          ),
                        ),

                        Text(
                          benefit.title,
                          textAlign:
                              TextAlign.center,
                          style:
                              AppTextStyles.of(
                            figmaSize: 10.5,
                            weight:
                                FontWeight.w500,
                            color:
                                AppColors.navy,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTINUE TO ORDER SUCCESS
  // ============================================================

  Widget _buildContinueButton(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height:
          AppTextStyles.fig(56),
      child: OutlinedButton(
        onPressed: () {
          final order = Order(
            id: '${widget.orderId}',
            productName: widget.product.name,
            amount: widget.product.total,
            paymentMethod: 'Razorpay',
            placedAt: DateTime.now(),
          );
          context.read<OrderProvider>().placeOrder(order);
          context.go('/order-success', extra: order);
        },
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              AppColors.purple,
          side:
              const BorderSide(
            color:
                AppColors.purple,
            width: 1.2,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color:
                  AppColors.purple,
              size: 27,
            ),

            SizedBox(
              width:
                  AppTextStyles.fig(12),
            ),

            Text(
              'Continue',
              style:
                  AppTextStyles.of(
                figmaSize: 16,
                weight:
                    FontWeight.w600,
                color:
                    AppColors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMMON CARD
  // ============================================================

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.all(
        AppTextStyles.fig(16),
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          13,
        ),
        border:
            Border.all(
          color:
              AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _sectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width:
              AppTextStyles.fig(44),
          height:
              AppTextStyles.fig(44),
          decoration:
              const BoxDecoration(
            color:
                AppColors.bgCardPurple,
            shape:
                BoxShape.circle,
          ),
          child: Icon(
            icon,
            color:
                AppColors.purple,
            size: 25,
          ),
        ),

        SizedBox(
          width:
              AppTextStyles.fig(12),
        ),

        Expanded(
          child: Text(
            title,
            style:
                AppTextStyles.of(
              figmaSize: 18,
              weight:
                  FontWeight.w700,
              color:
                  AppColors.navy,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PRICE ROW
  // ============================================================

  Widget _priceRow(
    String title,
    int amount, {
    Color? valueColor,
    Color? titleColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style:
                AppTextStyles.of(
              figmaSize: 13,
              weight:
                  FontWeight.w400,
              color:
                 titleColor?? AppColors.navy,
            ),
          ),
        ),

        Text(
          _money(amount),
          style:
              AppTextStyles.of(
            figmaSize: 14,
            weight:
                FontWeight.w600,
            color:
                valueColor ??
                AppColors.navy,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DASHED DIVIDER
  // ============================================================

  Widget _dashedDivider() {
    return Padding(
      padding:
          EdgeInsets.symmetric(
        vertical:
            AppTextStyles.fig(11),
      ),
      child: CustomPaint(
        painter:
            _DashedLinePainter(
          color:
              AppColors.divider,
        ),
        child:
            const SizedBox(
          width:
              double.infinity,
          height: 1,
        ),
      ),
    );
  }

  // ============================================================
  // MONEY
  // ============================================================

  String _money(int value) {
    final sign =
        value < 0 ? '-' : '';

    final number =
        value.abs().toString();

    final formatted =
        number.replaceAllMapped(
      RegExp(
        r'(\d)(?=(\d{3})+(?!\d))',
      ),
      (match) =>
          '${match[1]},',
    );

    return '$sign₹$formatted';
  }
}

// ================================================================
// PARTICLE SHAPE
// ================================================================

enum ParticleShape {
  circle,
  diamond,
}

// ================================================================
// DASHED LINE PAINTER
// ================================================================

class _DashedLinePainter
    extends CustomPainter {
  _DashedLinePainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const double dashWidth = 5.0;
    const double dashSpace = 5.0;

    double startX = 0.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3;

    while (startX < size.width) {
      final double endX = math.min(
        startX + dashWidth,
        size.width,
      );

      canvas.drawLine(
        Offset(startX, 0.0),
        Offset(endX, 0.0),
        paint,
      );

      startX +=
          dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(
    covariant _DashedLinePainter
        oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}

