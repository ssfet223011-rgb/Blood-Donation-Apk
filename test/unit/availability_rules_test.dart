import 'package:flutter_test/flutter_test.dart';
import 'package:bloodbond_bangladesh/core/config/app_config.dart';
import 'package:bloodbond_bangladesh/shared/models/donor_profile.dart';

void main() {
  group('Donor Availability & 90-Day Cooldown Tests', () {
    test('Donor cooldown is defined as 90 days', () {
      expect(AppConfig.donationCooldownDays, equals(90));
    });

    test('Donor availability status flags', () {
      final availableDonor = DonorProfile(
        id: '1',
        userId: 'u1',
        donorIdNumber: 'BB-DHA-000001',
        bloodGroup: 'O+',
        availabilityStatus: 'available',
      );
      expect(availableDonor.isAvailable, isTrue);
      expect(availableDonor.isResting, isFalse);

      final restingDonor = DonorProfile(
        id: '2',
        userId: 'u2',
        donorIdNumber: 'BB-CTG-000002',
        bloodGroup: 'A+',
        availabilityStatus: 'temporarily_unavailable',
      );
      expect(restingDonor.isAvailable, isFalse);
      expect(restingDonor.isResting, isTrue);

      final reviewDueDonor = DonorProfile(
        id: '3',
        userId: 'u3',
        donorIdNumber: 'BB-RAJ-000003',
        bloodGroup: 'B+',
        availabilityStatus: 'review_due',
      );
      expect(reviewDueDonor.isReviewDue, isTrue);
      expect(reviewDueDonor.isAvailable, isFalse);
    });

    test('Calculation of next review date is exactly 90 days from donation', () {
      final donationDate = DateTime(2026, 1, 15);
      final reviewDueDate = donationDate.add(const Duration(days: AppConfig.donationCooldownDays));

      expect(reviewDueDate.difference(donationDate).inDays, equals(90));
      expect(reviewDueDate, equals(DateTime(2026, 4, 15)));
    });
  });
}
