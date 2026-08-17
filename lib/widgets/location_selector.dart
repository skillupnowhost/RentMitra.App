import 'package:flutter/material.dart';

import '../services/location_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LocationSelector extends StatelessWidget {
  const LocationSelector({
    super.key,
    required this.city,
    this.onTap,
    this.status = LocationStatus.idle,
  });

  final String city;
  final VoidCallback? onTap;
  final LocationStatus status;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTextStyles.fig(14),
          vertical: AppTextStyles.fig(8),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == LocationStatus.detecting)
              SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.purple,
                ),
              )
            else
              const Icon(Icons.location_on, size: 15, color: AppColors.purple),
            SizedBox(width: AppTextStyles.fig(4)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppTextStyles.fig(110)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.of(
                      figmaSize: 14,
                      weight: FontWeight.w400,
                      color: AppColors.textGrayMed,
                    ),
                  ),
                  Text(
                    'Delivering in $city',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.of(
                      figmaSize: 10,
                      weight: FontWeight.w300,
                      color: AppColors.textGraySoft,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppTextStyles.fig(2)),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textGraySoft,
            ),
          ],
        ),
      ),
    );
  }
}
