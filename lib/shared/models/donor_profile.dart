class DonorProfile {
  final String id;
  final String userId;
  final String donorIdNumber; // e.g. BB-CTG-000001
  final String bloodGroup;
  final bool isVerified;
  final DateTime? verifiedAt;
  final String verificationBadge; // unverified, verified_donor, star_donor, blood_champion, legend
  final String availabilityStatus; // available, temporarily_unavailable, review_due, resting, busy, medical_hold
  final DateTime? availabilityReviewDueAt;
  final DateTime? latestVerifiedDonationAt;
  final int totalVerifiedDonations;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool hidePhoneNumber;
  final bool acceptEmergencyCalls;
  final int maxTravelDistanceKm;

  // Joined display attributes from profile and locations
  final String? fullName;
  final String? avatarUrl;
  final String? division;
  final String? district;
  final String? upazila;
  final String? thana;
  final String? localArea;
  final double? approxLatitude;
  final double? approxLongitude;
  final double? distanceKm;
  final String? distanceTier;
  final double avgRating;
  final int totalReviews;

  DonorProfile({
    required this.id,
    required this.userId,
    required this.donorIdNumber,
    required this.bloodGroup,
    this.isVerified = false,
    this.verifiedAt,
    this.verificationBadge = 'unverified',
    this.availabilityStatus = 'available',
    this.availabilityReviewDueAt,
    this.latestVerifiedDonationAt,
    this.totalVerifiedDonations = 0,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.hidePhoneNumber = true,
    this.acceptEmergencyCalls = true,
    this.maxTravelDistanceKm = 15,
    this.fullName,
    this.avatarUrl,
    this.division,
    this.district,
    this.upazila,
    this.thana,
    this.localArea,
    this.approxLatitude,
    this.approxLongitude,
    this.distanceKm,
    this.distanceTier,
    this.avgRating = 5.0,
    this.totalReviews = 0,
  });

  factory DonorProfile.fromJson(Map<String, dynamic> json) {
    return DonorProfile(
      id: json['id'] as String? ?? json['donor_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      donorIdNumber: json['donor_id_number'] as String? ?? 'BB-BD-000000',
      bloodGroup: json['blood_group'] as String? ?? 'O+',
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at'] as String) : null,
      verificationBadge: json['verification_badge'] as String? ?? 'unverified',
      availabilityStatus: json['availability_status'] as String? ?? 'available',
      availabilityReviewDueAt: json['availability_review_due_at'] != null
          ? DateTime.tryParse(json['availability_review_due_at'] as String)
          : null,
      latestVerifiedDonationAt: json['latest_verified_donation_at'] != null
          ? DateTime.tryParse(json['latest_verified_donation_at'] as String)
          : null,
      totalVerifiedDonations: (json['total_verified_donations'] as num?)?.toInt() ?? 0,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      hidePhoneNumber: json['hide_phone_number'] as bool? ?? true,
      acceptEmergencyCalls: json['accept_emergency_calls'] as bool? ?? true,
      maxTravelDistanceKm: (json['max_travel_distance_km'] as num?)?.toInt() ?? 15,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      division: json['division'] as String?,
      district: json['district'] as String?,
      upazila: json['upazila'] as String?,
      thana: json['thana'] as String?,
      localArea: json['local_area'] as String?,
      approxLatitude: (json['approx_latitude'] as num?)?.toDouble(),
      approxLongitude: (json['approx_longitude'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      distanceTier: json['distance_tier'] as String?,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 5.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isAvailable => availabilityStatus == 'available';
  bool get isReviewDue => availabilityStatus == 'review_due';
  bool get isResting => availabilityStatus == 'temporarily_unavailable';
}
