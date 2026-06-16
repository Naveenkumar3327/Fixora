import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Mock fallback location: Connaught Place, New Delhi
  static const double fallbackLat = 28.6304;
  static const double fallbackLng = 77.2177;
  static const String fallbackAddress = "Connaught Place, New Delhi, Delhi 110001";

  Future<Position> getCurrentLocation() async {
    try {
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

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      // Return a simulated mock position if hardware location fails (e.g. running in Windows simulator/missing permissions)
      return Position(
        latitude: fallbackLat,
        longitude: fallbackLng,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
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
