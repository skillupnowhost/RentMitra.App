import 'package:flutter/material.dart';

import '../services/location_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Manual "Select Your Location" fallback: search + city list + "use current
/// location" retry, shown when GPS is denied/unavailable or the user just
/// wants to change the delivery city themselves.
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  static const List<String> _serviceableCities = [
    'Chennai',
    'Bangalore',
    'Hyderabad',
    'Mumbai',
    'Delhi',
    'Pune',
    'Kolkata',
    'Coimbatore',
    'Kochi',
    'Ahmedabad',
  ];

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationPickerSheet(),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _controller = TextEditingController();
  String _query = '';
  bool _detecting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    final status = LocationController.instance.status.value;
    if (status == LocationStatus.deniedForever) {
      await LocationController.instance.openAppSettings();
      return;
    }
    if (status == LocationStatus.servicesDisabled) {
      await LocationController.instance.openLocationSettings();
      return;
    }

    setState(() => _detecting = true);
    final ok = await LocationController.instance.detectCurrentCity();
    if (!mounted) return;
    setState(() => _detecting = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      final message = switch (LocationController.instance.status.value) {
        LocationStatus.deniedForever => 'Location permission is blocked. Tap "Open App Settings" to allow it.',
        LocationStatus.servicesDisabled =>
          'Location services are off. Tap "Turn On Location" to enable them.',
        _ => "Couldn't detect your location. Please select your city below.",
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _select(String city) {
    LocationController.instance.setCity(city);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final results = LocationPickerSheet._serviceableCities
        .where((c) => c.toLowerCase().contains(_query.trim().toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(height: AppTextStyles.fig(10)),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTextStyles.fig(20),
                  AppTextStyles.fig(16),
                  AppTextStyles.fig(20),
                  AppTextStyles.fig(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Your Location',
                        style: AppTextStyles.of(
                          figmaSize: 20,
                          weight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textGraySoft,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTextStyles.fig(20),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTextStyles.fig(14),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        size: 18,
                        color: AppColors.textGraySoft,
                      ),
                      SizedBox(width: AppTextStyles.fig(8)),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: (v) => setState(() => _query = v),
                          style: AppTextStyles.of(
                            figmaSize: 15,
                            weight: FontWeight.w400,
                            color: AppColors.navy,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search city',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppTextStyles.fig(14)),
              if (_query.trim().isNotEmpty &&
                  !LocationPickerSheet._serviceableCities.any(
                    (c) => c.toLowerCase() == _query.trim().toLowerCase(),
                  ))
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTextStyles.fig(20),
                    0,
                    AppTextStyles.fig(20),
                    AppTextStyles.fig(14),
                  ),
                  child: GestureDetector(
                    onTap: () => _select(_query.trim()),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: AppTextStyles.fig(12),
                        horizontal: AppTextStyles.fig(14),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgCardPurple,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.purple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_location_alt_outlined,
                            size: 18,
                            color: AppColors.purple,
                          ),
                          SizedBox(width: AppTextStyles.fig(8)),
                          Expanded(
                            child: Text(
                              'Use "${_query.trim()}" as my location',
                              style: AppTextStyles.of(
                                figmaSize: 14,
                                weight: FontWeight.w600,
                                color: AppColors.purple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTextStyles.fig(20),
                ),
                child: ValueListenableBuilder<LocationStatus>(
                  valueListenable: LocationController.instance.status,
                  builder: (context, status, _) {
                    final (icon, label) = switch (status) {
                      LocationStatus.deniedForever => (
                        Icons.settings,
                        'Open App Settings',
                      ),
                      LocationStatus.servicesDisabled => (
                        Icons.location_disabled,
                        'Turn On Location',
                      ),
                      _ => (Icons.my_location, 'Use current location'),
                    };
                    return GestureDetector(
                      onTap: _detecting ? null : _useCurrentLocation,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: AppTextStyles.fig(13),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCardPurple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_detecting)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.purple,
                                ),
                              )
                            else
                              Icon(icon, size: 17, color: AppColors.purple),
                            SizedBox(width: AppTextStyles.fig(8)),
                            Text(
                              _detecting ? 'Detecting your location…' : label,
                              style: AppTextStyles.of(
                                figmaSize: 14,
                                weight: FontWeight.w600,
                                color: AppColors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: AppTextStyles.fig(10)),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTextStyles.fig(20),
                    vertical: AppTextStyles.fig(8),
                  ),
                  itemCount: results.length,
                  separatorBuilder: (context, i) =>
                      Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, i) {
                    final city = results[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textGraySoft,
                        size: 20,
                      ),
                      title: Text(
                        city,
                        style: AppTextStyles.of(
                          figmaSize: 15,
                          weight: FontWeight.w400,
                          color: AppColors.navy,
                        ),
                      ),
                      onTap: () => _select(city),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
