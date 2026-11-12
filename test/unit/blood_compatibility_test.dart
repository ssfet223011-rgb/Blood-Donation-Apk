import 'package:flutter_test/flutter_test.dart';
import 'package:bloodbond_bangladesh/core/constants/bangladesh_locations.dart';

void main() {
  group('Bangladesh Blood Group Compatibility Matrix Tests', () {
    test('O- is universal red blood cell donor to all blood groups', () {
      for (final recipient in BangladeshLocations.bloodGroups) {
        expect(
          BangladeshLocations.canDonate('O-', recipient),
          isTrue,
          reason: 'O- must be able to donate to $recipient',
        );
      }
    });

    test('AB+ is universal recipient from all compatible donor groups', () {
      for (final donor in BangladeshLocations.bloodGroups) {
        expect(
          BangladeshLocations.canDonate(donor, 'AB+'),
          isTrue,
          reason: 'AB+ recipient must be able to receive from $donor',
        );
      }
    });

    test('O+ can donate to O+, A+, B+, AB+ but NOT to Rh negative recipients', () {
      expect(BangladeshLocations.canDonate('O+', 'O+'), isTrue);
      expect(BangladeshLocations.canDonate('O+', 'A+'), isTrue);
      expect(BangladeshLocations.canDonate('O+', 'B+'), isTrue);
      expect(BangladeshLocations.canDonate('O+', 'AB+'), isTrue);

      expect(BangladeshLocations.canDonate('O+', 'O-'), isFalse);
      expect(BangladeshLocations.canDonate('O+', 'A-'), isFalse);
      expect(BangladeshLocations.canDonate('O+', 'B-'), isFalse);
      expect(BangladeshLocations.canDonate('O+', 'AB-'), isFalse);
    });

    test('A+ recipient can only receive from A+, A-, O+, O-', () {
      final compatible = BangladeshLocations.getCompatibleDonors('A+');
      expect(compatible, containsAll(['A+', 'A-', 'O+', 'O-']));
      expect(compatible.contains('B+'), isFalse);
      expect(compatible.contains('AB+'), isFalse);
    });

    test('Exact blood group match is always compatible', () {
      for (final group in BangladeshLocations.bloodGroups) {
        expect(BangladeshLocations.canDonate(group, group), isTrue);
      }
    });
  });
}
