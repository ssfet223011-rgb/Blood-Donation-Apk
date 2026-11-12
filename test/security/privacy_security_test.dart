import 'package:flutter_test/flutter_test.dart';
import 'package:bloodbond_bangladesh/core/security/security_vault.dart';
import 'package:bloodbond_bangladesh/shared/models/donor_profile.dart';

void main() {
  group('Security & Privacy Protocol Tests', () {
    test('Coordinate obfuscation rounds to ~1km precision (2 decimal points)', () {
      const rawLat = 23.8103429102;
      const rawLon = 90.4125829103;

      final safeLat = SecurityVault.obfuscateCoordinate(rawLat);
      final safeLon = SecurityVault.obfuscateCoordinate(rawLon);

      expect(safeLat, equals(23.81));
      expect(safeLon, equals(90.41));
    });

    test('DonorProfile JSON parsing does not leak phone number in public model', () {
      final json = {
        'id': 'd-101',
        'user_id': 'u-501',
        'donor_id_number': 'BB-CTG-000001',
        'blood_group': 'O+',
        'is_verified': true,
        'verification_badge': 'blood_champion',
        'availability_status': 'available',
        'total_verified_donations': 12,
        'full_name': 'Tanvir Hossain',
        'district': 'Chattogram',
        'hide_phone_number': true,
      };

      final donor = DonorProfile.fromJson(json);

      expect(donor.donorIdNumber, equals('BB-CTG-000001'));
      expect(donor.hidePhoneNumber, isTrue);
      // Emergency contact is private and should be null when not provided
      expect(donor.emergencyContactPhone, isNull);
    });
  });
}
