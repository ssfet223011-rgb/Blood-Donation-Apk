class DonationRecord {
  final String id;
  final String donorId;
  final String? bloodRequestId;
  final String? organizationId;
  final DateTime donationDate;
  final String donationType; // whole_blood, platelets, plasma, red_cells
  final int units;
  final String? hospitalName;
  final String? hospitalDistrict;
  final String verificationStatus; // pending, verified, rejected
  final String? notes;
  final String? certificateId;

  DonationRecord({
    required this.id,
    required this.donorId,
    this.bloodRequestId,
    this.organizationId,
    required this.donationDate,
    this.donationType = 'whole_blood',
    this.units = 1,
    this.hospitalName,
    this.hospitalDistrict,
    this.verificationStatus = 'pending',
    this.notes,
    this.certificateId,
  });

  factory DonationRecord.fromJson(Map<String, dynamic> json) {
    return DonationRecord(
      id: json['id'] as String,
      donorId: json['donor_id'] as String,
      bloodRequestId: json['blood_request_id'] as String?,
      organizationId: json['organization_id'] as String?,
      donationDate: DateTime.parse(json['donation_date'] as String),
      donationType: json['donation_type'] as String? ?? 'whole_blood',
      units: (json['units'] as num?)?.toInt() ?? 1,
      hospitalName: json['hospital_name'] as String?,
      hospitalDistrict: json['hospital_district'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      certificateId: json['certificate_id'] as String?,
    );
  }

  bool get isVerified => verificationStatus == 'verified';
}
