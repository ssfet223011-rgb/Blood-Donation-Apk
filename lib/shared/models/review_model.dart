class ReviewModel {
  final String id;
  final String reviewerId;
  final String donorId;
  final String bloodRequestId;
  final int rating;
  final String? reviewText;
  final String moderationStatus;
  final DateTime createdAt;
  final String? reviewerName;

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.donorId,
    required this.bloodRequestId,
    required this.rating,
    this.reviewText,
    this.moderationStatus = 'approved',
    required this.createdAt,
    this.reviewerName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      reviewerId: json['reviewer_id'] as String,
      donorId: json['donor_id'] as String,
      bloodRequestId: json['blood_request_id'] as String,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      reviewText: json['review_text'] as String?,
      moderationStatus: json['moderation_status'] as String? ?? 'approved',
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      reviewerName: json['reviewer_name'] as String?,
    );
  }
}
