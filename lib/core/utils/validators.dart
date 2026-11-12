/// Form and Input Validators for BloodBond Bangladesh
class Validators {
  /// Validates Bangladesh phone numbers: +8801XXXXXXXXX or 01XXXXXXXXX
  static String? validateBangladeshPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final clean = value.replaceAll(RegExp(r'[\s\-]'), '');
    final bdPhoneRegex = RegExp(r'^(\+?8801|01)[3-9]\d{8}$');
    if (!bdPhoneRegex.hasMatch(clean)) {
      return 'Enter a valid 11-digit Bangladesh mobile number (e.g. 017XXXXXXXX)';
    }
    return null;
  }

  /// Validates email address
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates password strength (min 6 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates donor eligibility based on Date of Birth (18 to 60 years old)
  static String? validateDonorAge(DateTime? dob) {
    if (dob == null) {
      return 'Date of birth is required';
    }
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    if (age < 18) {
      return 'You must be at least 18 years old to register as a donor.';
    }
    if (age > 60) {
      return 'National health guidelines recommend donor age between 18 and 60.';
    }
    return null;
  }

  /// Formats raw Bangladesh phone number to standard national format
  static String formatBangladeshPhone(String raw) {
    var clean = raw.replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.startsWith('+88')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('88')) {
      clean = clean.substring(2);
    }
    return clean;
  }
}
