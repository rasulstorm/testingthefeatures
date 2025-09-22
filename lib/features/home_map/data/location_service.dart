import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../domain/location_models.dart';

class LocationService {
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 25,
  );

  Future<LocationPermissionState> checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionState.denied;
    }

    final status = await Geolocator.checkPermission();
    return _mapPermission(status);
  }

  Future<LocationPermissionState> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionState.denied;
    }

    final status = await Geolocator.requestPermission();
    return _mapPermission(status);
  }

  Stream<Position> positionStream({LocationSettings? settings}) {
    return Geolocator.getPositionStream(
      locationSettings: settings ?? _locationSettings,
    );
  }

  Future<Position?> currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } on LocationServiceDisabledException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  LocationPermissionState _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionState.granted;
      case LocationPermission.deniedForever:
        return LocationPermissionState.permanentlyDenied;
      case LocationPermission.unableToDetermine:
        return LocationPermissionState.unknown;
      case LocationPermission.denied:
      default:
        return LocationPermissionState.denied;
    }
  }
}
