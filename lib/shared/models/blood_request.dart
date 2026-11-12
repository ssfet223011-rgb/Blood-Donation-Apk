class BloodRequest {
  final String id;
  final String requesterId;
  final String patientName;
  final String bloodGroup;
  final int unitsNeeded;
  final int unitsReceived;
  final String hospitalName;
  final String division;
  final String district;
  final String? upazila;
  final String? thana;
  final String? hospitalAddress;
  final double? latitude;
  final double? longitude;
  final String urgencyLevel; // normal, urgent, emergency
  final DateTime requiredDate;
  final String? requiredTime;
  final String contactPersonName;
  final String contactPhone;
  final String? secondaryPhone;
  final String? medicalReason;
  final String status; // draft, submitted, active, matching_donors, donor_responses, fulfilled, completed, cancelled
  final bool isVerified;
  final DateTime? createdAt;

  BloodRequest({
    required this.id,
    required this.requesterId,
    required this.patientName,
    required this.bloodGroup,
    this.unitsNeeded = 1,
    this.unitsReceived = 0,
    required this.hospitalName,
    required this.division,
    required this.district,
    this.upazila,
    this.thana,
    this.hospitalAddress,
    this.latitude,
    this.longitude,
    this.urgencyLevel = 'normal',
    required this.requiredDate,
    this.requiredTime,
    required this.contactPersonName,
    required this.contactPhone,
    this.secondaryPhone,
    this.medicalReason,
    this.status = 'submitted',
    this.isVerified = false,
    this.createdAt,
  });

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    return BloodRequest(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      patientName: json['patient_name'] as String,
      bloodGroup: json['blood_group'] as String,
      unitsNeeded: (json['units_needed'] as num?)?.toInt() ?? 1,
      unitsReceived: (json['units_received'] as num?)?.toInt() ?? 0,
      hospitalName: json['hospital_name'] as String,
      division: json['division'] as String,
      district: json['district'] as String,
      upazila: json['upazila'] as String?,
      thana: json['thana'] as String?,
      hospitalAddress: json['hospital_address'] as String?,
      urgencyLevel: json['urgency_level'] as String? ?? 'normal',
      requiredDate: DateTime.parse(json['required_date'] as String),
      requiredTime: json['required_time'] as String?,
      contactPersonName: json['contact_person_name'] as String,
      contactPhone: json['contact_phone'] as String,
      secondaryPhone: json['secondary_phone'] as String?,
      medicalReason: json['medical_reason'] as String?,
      status: json['status'] as String? ?? 'submitted',
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requester_id': requesterId,
      'patient_name': patientName,
      'blood_group': bloodGroup,
      'units_needed': unitsNeeded,
      'hospital_name': hospitalName,
      'division': division,
      'district': district,
      'upazila': upazila,
      'thana': thana,
      'hospital_address': hospitalAddress,
      'urgency_level': urgencyLevel,
      'required_date': requiredDate.toIso8601String().split('T').first,
      'required_time': requiredTime,
      'contact_person_name': contactPersonName,
      'contact_phone': contactPhone,
      'secondary_phone': secondaryPhone,
      'medical_reason': medicalReason,
      'status': status,
    };
  }

  bool get isEmergency => urgencyLevel == 'emergency';
  bool get isUrgent => urgencyLevel == 'urgent' || urgencyLevel == 'emergency';
}
