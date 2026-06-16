import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Mock fallback location: Connaught Place, New Delhi
  static const double fallbackLat = 28.6304;
  static const double fallbackLng = 77.2177;
  static const String fallbackAddress = "Connaught Place, New Delhi, Delhi 110001";

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    try {
      // 1. Attempt High Accuracy GPS mode first (6-second timeout)
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (e) {
      try {
        // 2. Fallback to Medium Accuracy Network Location (Wifi/Cell tower, 4-second timeout)
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 4),
        );
      } catch (e2) {
        // 3. Fallback to Last Known Position if available
        final Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return lastKnown;
        }
        
        // 4. Fallback to Low Accuracy (3-second timeout)
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3),
        );
      }
    }
  }

  Stream<Position> getPositionStream() {
    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20,
        intervalDuration: const Duration(seconds: 30),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20,
        activityType: ActivityType.other,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20,
      );
    }
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng).timeout(const Duration(seconds: 4));
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return "${place.name != null && place.name!.isNotEmpty ? '${place.name}, ' : ''}${place.subLocality != null && place.subLocality!.isNotEmpty ? '${place.subLocality}, ' : ''}${place.locality ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}";
      }
      return "$lat, $lng";
    } catch (e) {
      if (lat == fallbackLat && lng == fallbackLng) {
        return fallbackAddress;
      }
      return "Main Street, Metro Area, $lat, $lng";
    }
  }

  double calculateDistanceInKm(double startLat, double startLng, double endLat, double endLng) {
    double distanceInMeters = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    return distanceInMeters / 1000.0;
  }
}
