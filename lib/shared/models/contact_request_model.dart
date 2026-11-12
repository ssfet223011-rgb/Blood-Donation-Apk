class ContactRequestModel {
  final String id;
  final String requesterId;
  final String donorId;
  final String? bloodRequestId;
  final String status; // pending, approved, declined, expired, revoked
  final String? requestReason;
  final DateTime expiresAt;
  final DateTime? approvedAt;
  final DateTime createdAt;

  // Joined fields for display
  final String? requesterName;
  final String? donorName;
  final String? donorPhone; // Populated only when approved!

  ContactRequestModel({
    required this.id,
    required this.requesterId,
    required this.donorId,
    this.bloodRequestId,
    this.status = 'pending',
    this.requestReason,
    required this.expiresAt,
    this.approvedAt,
    required this.createdAt,
    this.requesterName,
    this.donorName,
    this.donorPhone,
  });

  factory ContactRequestModel.fromJson(Map<String, dynamic> json) {
    return ContactRequestModel(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      donorId: json['donor_id'] as String,
      bloodRequestId: json['blood_request_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      requestReason: json['request_reason'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      requesterName: json['requester_name'] as String?,
      donorName: json['donor_name'] as String?,
      donorPhone: json['donor_phone'] as String?,
    );
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
