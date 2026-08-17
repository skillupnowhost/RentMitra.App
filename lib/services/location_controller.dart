import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocationStatus {
  idle,
  detecting,
  detected,
  denied,
  deniedForever,
  servicesDisabled,
  unavailable,
  manual,
}

/// App-wide selected delivery city, shared by the home screen and every
/// product listing page. Deliberately a plain [ValueNotifier] singleton
/// rather than a state-management package — one mutable value, read by a
/// handful of [LocationSelector] instances, doesn't need more than that.
class LocationController {
  LocationController._();

  static final LocationController instance = LocationController._();

  static const _cityPrefsKey = 'rentmitra.selected_city';
  static const _manualPrefsKey = 'rentmitra.city_is_manual';

  final ValueNotifier<String> city = ValueNotifier<String>('Chennai');
  final ValueNotifier<LocationStatus> status = ValueNotifier<LocationStatus>(
    LocationStatus.idle,
  );

  bool _autoDetectAttempted = false;
  StreamSubscription<Position>? _liveSub;

  /// Loads a previously-saved manual city choice, if any. Call once at app
  /// startup, before the home screen mounts, so a returning user's explicit
  /// pick isn't silently clobbered by auto-detect.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString(_cityPrefsKey);
    final wasManual = prefs.getBool(_manualPrefsKey) ?? false;
    if (wasManual && savedCity != null && savedCity.trim().isNotEmpty) {
      city.value = savedCity;
      status.value = LocationStatus.manual;
      _autoDetectAttempted = true;
    }
  }

  Future<void> setCity(String value) async {
    _stopLiveTracking();
    city.value = value;
    status.value = LocationStatus.manual;
    _autoDetectAttempted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityPrefsKey, value);
    await prefs.setBool(_manualPrefsKey, true);
  }

  /// Runs once per app session (guarded by [_autoDetectAttempted]) so
  /// revisiting the home screen doesn't re-prompt for permission every time,
  /// and never runs at all if the user already made a manual choice.
  Future<void> autoDetectOnce() async {
    if (_autoDetectAttempted) return;
    _autoDetectAttempted = true;
    await detectCurrentCity();
  }

  Future<bool> detectCurrentCity() async {
    status.value = LocationStatus.detecting;
    try {
      final ok = await _detect().timeout(const Duration(seconds: 12));
      if (ok) _startLiveTracking();
      return ok;
    } catch (_) {
      // Covers TimeoutException, MissingPluginException (no plugin
      // implementation on the current platform/target), and any
      // geolocator/geocoding failure — all fall back to manual selection
      // rather than leaving the UI stuck on "Detecting your location…".
      status.value = LocationStatus.unavailable;
      return false;
    }
  }

  Future<bool> _detect() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      status.value = LocationStatus.servicesDisabled;
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      status.value = LocationStatus.deniedForever;
      return false;
    }
    if (permission == LocationPermission.denied) {
      status.value = LocationStatus.denied;
      return false;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
    return _resolveAndApply(position);
  }

  Future<bool> _resolveAndApply(Position position) async {
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isEmpty) {
      status.value = LocationStatus.unavailable;
      return false;
    }

    final place = placemarks.first;
    final detected = place.locality?.trim().isNotEmpty == true
        ? place.locality!.trim()
        : (place.subAdministrativeArea?.trim().isNotEmpty == true
              ? place.subAdministrativeArea!.trim()
              : place.administrativeArea?.trim());

    if (detected == null || detected.isEmpty) {
      status.value = LocationStatus.unavailable;
      return false;
    }

    city.value = detected;
    status.value = LocationStatus.detected;
    return true;
  }

  /// Keeps the delivery city fresh as the user moves, without re-prompting
  /// for permission or re-running the full [_detect] flow. Only updates the
  /// city while auto-detection is the active source — a manual pick (via
  /// [setCity]) stops this stream so live updates never override an
  /// explicit choice.
  void _startLiveTracking() {
    if (_liveSub != null) return;
    _liveSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 300,
          ),
        ).listen(
          (position) {
            if (status.value == LocationStatus.manual) return;
            _resolveAndApply(position);
          },
          onError: (_) {
            // Stream errors (permission revoked mid-session, GPS turned off,
            // etc.) shouldn't crash the app — just stop tracking silently.
            _stopLiveTracking();
          },
        );
  }

  void _stopLiveTracking() {
    _liveSub?.cancel();
    _liveSub = null;
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
