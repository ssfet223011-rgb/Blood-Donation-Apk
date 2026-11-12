/// Complete Bangladesh Administrative Hierarchy and Blood Group Constants
class BangladeshLocations {
  static const List<String> divisions = [
    'Dhaka',
    'Chattogram',
    'Rajshahi',
    'Khulna',
    'Barishal',
    'Sylhet',
    'Rangpur',
    'Mymensingh',
  ];

  static const Map<String, List<String>> districtsByDivision = {
    'Dhaka': [
      'Dhaka',
      'Gazipur',
      'Kishoreganj',
      'Manikganj',
      'Munshiganj',
      'Narayanganj',
      'Narsingdi',
      'Tangail',
      'Faridpur',
      'Gopalganj',
      'Madaripur',
      'Rajbari',
      'Shariatpur',
    ],
    'Chattogram': [
      'Chattogram',
      'Cox\'s Bazar',
      'Cumilla',
      'Feni',
      'Brahmanbaria',
      'Rangamati',
      'Noakhali',
      'Chandpur',
      'Lakshmipur',
      'Khagrachhari',
      'Bandarban',
    ],
    'Rajshahi': [
      'Rajshahi',
      'Bogura',
      'Pabna',
      'Sirajganj',
      'Naogaon',
      'Natore',
      'Chapai Nawabganj',
      'Joypurhat',
    ],
    'Khulna': [
      'Khulna',
      'Jashore',
      'Satkhira',
      'Bagerhat',
      'Kushtia',
      'Jhenaidah',
      'Chuadanga',
      'Meherpur',
      'Narail',
      'Magura',
    ],
    'Barishal': [
      'Barishal',
      'Patuakhali',
      'Bhola',
      'Pirojpur',
      'Barguna',
      'Jhalokati',
    ],
    'Sylhet': [
      'Sylhet',
      'Moulvibazar',
      'Habiganj',
      'Sunamganj',
    ],
    'Rangpur': [
      'Rangpur',
      'Dinajpur',
      'Gaibandha',
      'Kurigram',
      'Lalmonirhat',
      'Nilphamari',
      'Panchagarh',
      'Thakurgaon',
    ],
    'Mymensingh': [
      'Mymensingh',
      'Jamalpur',
      'Netrokona',
      'Sherpur',
    ],
  };

  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  /// Compatibility Matrix: Returns list of compatible donor groups for a given recipient
  static List<String> getCompatibleDonors(String recipientGroup) {
    switch (recipientGroup) {
      case 'A+':
        return ['A+', 'A-', 'O+', 'O-'];
      case 'A-':
        return ['A-', 'O-'];
      case 'B+':
        return ['B+', 'B-', 'O+', 'O-'];
      case 'B-':
        return ['B-', 'O-'];
      case 'AB+': // Universal recipient
        return ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
      case 'AB-':
        return ['AB-', 'A-', 'B-', 'O-'];
      case 'O+':
        return ['O+', 'O-'];
      case 'O-': // Can only receive from O-
        return ['O-'];
      default:
        return [recipientGroup];
    }
  }

  /// Check if a specific donor group can donate to a recipient
  static bool canDonate(String donorGroup, String recipientGroup) {
    return getCompatibleDonors(recipientGroup).contains(donorGroup);
  }
}
