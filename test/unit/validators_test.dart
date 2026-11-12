import 'package:flutter_test/flutter_test.dart';
import 'package:bloodbond_bangladesh/core/utils/validators.dart';

void main() {
  group('Bangladesh Validators Unit Tests', () {
    test('Validates standard 11-digit Bangladesh phone numbers', () {
      expect(Validators.validateBangladeshPhone('01712345678'), isNull);
      expect(Validators.validateBangladeshPhone('01812345678'), isNull);
      expect(Validators.validateBangladeshPhone('01912345678'), isNull);
      expect(Validators.validateBangladeshPhone('+8801312345678'), isNull);
      expect(Validators.validateBangladeshPhone('01512345678'), isNull);
    });

    test('Rejects invalid phone numbers', () {
      expect(Validators.validateBangladeshPhone(''), isNotNull);
      expect(Validators.validateBangladeshPhone('01212345678'), isNotNull); // 012 is invalid in BD
      expect(Validators.validateBangladeshPhone('12345'), isNotNull);
      expect(Validators.validateBangladeshPhone('017123456789999'), isNotNull);
    });

    test('Validates email addresses', () {
      expect(Validators.validateEmail('donor@bloodbond.bd'), isNull);
      expect(Validators.validateEmail('user.name@gmail.com'), isNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
    });

    test('Validates donor age eligibility (18 to 60)', () {
      final now = DateTime.now();
      final eligibleDob = DateTime(now.year - 25, now.month, now.day);
      final underAgeDob = DateTime(now.year - 16, now.month, now.day);
      final overAgeDob = DateTime(now.year - 65, now.month, now.day);

      expect(Validators.validateDonorAge(eligibleDob), isNull);
      expect(Validators.validateDonorAge(underAgeDob), isNotNull);
      expect(Validators.validateDonorAge(overAgeDob), isNotNull);
    });
  });
}
