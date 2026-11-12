class UserProfile {
  final String id;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String division;
  final String district;
  final String? upazila;
  final String? thana;
  final String? localArea;
  final bool isActive;
  final List<String> roles;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    required this.division,
    required this.district,
    this.upazila,
    this.thana,
    this.localArea,
    this.isActive = true,
    this.roles = const ['registered_user'],
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, {List<String>? roles}) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Anonymous',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      bloodGroup: json['blood_group'] as String?,
      division: json['division'] as String? ?? 'Dhaka',
      district: json['district'] as String? ?? 'Dhaka',
      upazila: json['upazila'] as String?,
      thana: json['thana'] as String?,
      localArea: json['local_area'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      roles: roles ?? (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['registered_user'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'gender': gender,
      'blood_group': bloodGroup,
      'division': division,
      'district': district,
      'upazila': upazila,
      'thana': thana,
      'local_area': localArea,
      'is_active': isActive,
    };
  }

  bool get isDonor => roles.contains('donor');
  bool get isAdmin => roles.contains('admin') || roles.contains('super_admin');
}
