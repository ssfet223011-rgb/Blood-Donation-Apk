import 'package:flutter_test/flutter_test.dart';
import 'package:bloodbond_bangladesh/core/services/location_service.dart';

void main() {
  group('Location Distance & Spatial Tiering Tests', () {
    test('Calculates distance between Dhaka and Chattogram accurately', () {
      final dhaka = LocationService.districtCoordinates['Dhaka']!;
      final ctg = LocationService.districtCoordinates['Chattogram']!;

      final distanceKm = LocationService.calculateDistanceKm(
        dhaka.$1,
        dhaka.$2,
        ctg.$1,
        ctg.$2,
      );

      // Actual geographic distance between Dhaka and Chattogram is ~205-220 km
      expect(distanceKm, greaterThan(190.0));
      expect(distanceKm, lessThan(240.0));
    });

    test('Zero distance for identical coordinates', () {
      final dhaka = LocationService.districtCoordinates['Dhaka']!;
      final dist = LocationService.calculateDistanceKm(
        dhaka.$1,
        dhaka.$2,
        dhaka.$1,
        dhaka.$2,
      );
      expect(dist, equals(0.0));
    });

    test('Classifies within 5km tier for very close locations', () {
      // 0.02 degrees latitude difference is ~2.2 km
      final dist = LocationService.calculateDistanceKm(23.8103, 90.4125, 23.8303, 90.4125);
      expect(dist, lessThan(5.0));
    });
  });
}
