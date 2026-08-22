import 'dart:async';

import 'package:flutter/material.dart';

import '../services/location_controller.dart';
import '../services/place_search_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Manual "Select Your Location" fallback: search + city list + "use current
/// location" retry, shown when GPS is denied/unavailable or the user just
/// wants to change the delivery city themselves.
class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  static const Map<String, List<String>> _citiesByState = {
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Tiruchirappalli',
      'Salem',
      'Tirunelveli',
      'Erode',
      'Vellore',
      'Thoothukudi',
      'Dindigul',
      'Thanjavur',
      'Karur',
      'Nagercoil',
      'Hosur',
      'Cuddalore',
      'Kanchipuram',
    ],
    'Other States': [
      'Bangalore',
      'Hyderabad',
      'Mumbai',
      'Delhi',
      'Pune',
      'Kolkata',
      'Kochi',
      'Thiruvananthapuram',
      'Ahmedabad',
      'Surat',
      'Jaipur',
      'Lucknow',
      'Chandigarh',
      'Bhopal',
      'Indore',
      'Nagpur',
      'Visakhapatnam',
      'Vijayawada',
    ],
  };

  static List<String> get _allCities =>
      _citiesByState.values.expand((cities) => cities).toList();

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

  List<PlaceSuggestion> _remoteResults = const [];
  bool _searching = false;
  Timer? _debounce;
  int _searchToken = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.length < 3) {
      setState(() {
        _remoteResults = const [];
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _runSearch(trimmed);
    });
  }

  Future<void> _runSearch(String query) async {
    final token = ++_searchToken;
    debugPrint('LOCSEARCH: running search for "$query"');
    try {
      final results = await PlaceSearchService.instance.search(query);
      debugPrint('LOCSEARCH: got ${results.length} results: ${results.map((r) => r.label).toList()}');
      if (!mounted || token != _searchToken) return;
      setState(() {
        _remoteResults = results;
        _searching = false;
      });
    } catch (e, st) {
      // Offline or Nominatim unreachable — the "Use it as typed" fallback
      // below still lets the user pick a manually-entered city.
      debugPrint('LOCSEARCH: error $e\n$st');
      if (!mounted || token != _searchToken) return;
      setState(() {
        _remoteResults = const [];
        _searching = false;
      });
    }
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
    return ValueListenableBuilder<String>(
      valueListenable: LocationController.instance.city,
      builder: (context, currentCity, _) => _buildSheet(context, currentCity),
    );
  }

  Widget _buildSheet(BuildContext context, String currentCity) {
    final query = _query.trim().toLowerCase();
    final rows = <_LocationRow>[];
    for (final entry in LocationPickerSheet._citiesByState.entries) {
      final matches = entry.value
          .where((c) => c.toLowerCase().contains(query))
          .toList();
      if (matches.isEmpty) continue;
      rows.add(_LocationRow.header(entry.key));
      rows.addAll(matches.map(_LocationRow.city));
    }

    final localNames = LocationPickerSheet._allCities
        .map((c) => c.toLowerCase())
        .toSet();
    final newRemoteResults = _remoteResults
        .where((r) => !localNames.contains(r.name.toLowerCase()))
        .toList();
    if (newRemoteResults.isNotEmpty) {
      rows.add(_LocationRow.header('Search Results'));
      rows.addAll(
        newRemoteResults.map(
          (r) => _LocationRow.city(r.label, value: r.name),
        ),
      );
    }

    final normalizedCurrent = currentCity.trim().toLowerCase();
    final currentIsListed = LocationPickerSheet._allCities.any(
      (c) => c.toLowerCase() == normalizedCurrent,
    );

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
                          onChanged: _onQueryChanged,
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
                      if (_searching)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.purple,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppTextStyles.fig(14)),
              if (_query.trim().isNotEmpty &&
                  !LocationPickerSheet._allCities.any(
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
              if (!currentIsListed &&
                  currentCity.trim().isNotEmpty &&
                  _query.trim().isEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTextStyles.fig(20),
                    0,
                    AppTextStyles.fig(20),
                    AppTextStyles.fig(4),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.my_location,
                      color: AppColors.purple,
                      size: 20,
                    ),
                    title: Text(
                      currentCity,
                      style: AppTextStyles.of(
                        figmaSize: 15,
                        weight: FontWeight.w600,
                        color: AppColors.purple,
                      ),
                    ),
                    subtitle: Text(
                      'Your current location',
                      style: AppTextStyles.of(
                        figmaSize: 11,
                        weight: FontWeight.w400,
                        color: AppColors.textGraySoft,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: AppColors.purple,
                      size: 18,
                    ),
                    onTap: () => Navigator.of(context).pop(),
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
                  itemCount: rows.length,
                  separatorBuilder: (context, i) {
                    if (rows[i].isHeader || rows[i + 1].isHeader) {
                      return const SizedBox.shrink();
                    }
                    return Divider(height: 1, color: AppColors.divider);
                  },
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    if (row.isHeader) {
                      return Padding(
                        padding: EdgeInsets.only(
                          top: i == 0 ? 0 : AppTextStyles.fig(14),
                          bottom: AppTextStyles.fig(6),
                        ),
                        child: Text(
                          row.text,
                          style: AppTextStyles.of(
                            figmaSize: 12,
                            weight: FontWeight.w700,
                            color: AppColors.textGraySoft,
                            letterSpacing: 0.4,
                          ),
                        ),
                      );
                    }

                    final city = row.value;
                    final isSelected =
                        city.toLowerCase() == normalizedCurrent;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isSelected
                            ? Icons.location_on
                            : Icons.location_on_outlined,
                        color: isSelected
                            ? AppColors.purple
                            : AppColors.textGraySoft,
                        size: 20,
                      ),
                      title: Text(
                        row.text,
                        style: AppTextStyles.of(
                          figmaSize: 15,
                          weight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.purple
                              : AppColors.navy,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.purple,
                              size: 18,
                            )
                          : null,
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

class _LocationRow {
  const _LocationRow.header(this.text) : isHeader = true, value = '';
  const _LocationRow.city(this.text, {String? value})
    : isHeader = false,
      value = value ?? text;

  /// What's shown in the row.
  final String text;

  /// What's actually selected on tap — differs from [text] for remote
  /// results, which display as "City, State" but select just the city.
  final String value;
  final bool isHeader;
}
