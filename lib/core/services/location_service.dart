import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Request GPS permission and fetch current position
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Haversine Formula: Calculates distance in km between two lat/lng coordinates
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return double.parse((earthRadiusKm * c).toStringAsFixed(2));
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Get approximate centroid for Bangladesh districts
  static Map<String, (double lat, double lon)> districtCoordinates = {
    'Dhaka': (23.8103, 90.4125),
    'Chattogram': (22.3569, 91.7832),
    'Rajshahi': (24.3745, 88.6042),
    'Khulna': (22.8456, 89.5403),
    'Barishal': (22.7010, 90.3535),
    'Sylhet': (24.8949, 91.8687),
    'Rangpur': (25.7439, 89.2752),
    'Mymensingh': (24.7471, 90.4203),
    'Gazipur': (23.9999, 90.4203),
    'Cumilla': (23.4682, 91.1788),
    'Bogura': (24.8465, 89.3770),
    'Cox\'s Bazar': (21.4272, 92.0058),
  };
}
