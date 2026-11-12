import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/models/review_model.dart';
import '../../shared/widgets/empty_state.dart';

class DonorReviewsScreen extends StatefulWidget {
  final String donorId;

  const DonorReviewsScreen({super.key, required this.donorId});

  @override
  State<DonorReviewsScreen> createState() => _DonorReviewsScreenState();
}

class _DonorReviewsScreenState extends State<DonorReviewsScreen> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final res = await SupabaseService.client
          .from('reviews')
          .select('*, profiles:reviewer_id(full_name)')
          .eq('donor_id', widget.donorId)
          .eq('moderation_status', 'approved')
          .order('created_at', ascending: false);

      _reviews = (res as List<dynamic>).map((item) {
        final prof = item['profiles'] as Map<String, dynamic>?;
        final map = Map<String, dynamic>.from(item as Map);
        map['reviewer_name'] = prof?['full_name'];
        return ReviewModel.fromJson(map);
      }).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verified Donor Feedback')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.star_border,
                  title: 'No Reviews Yet',
                  message: 'Reviews can only be submitted by verified seekers following a successfully completed blood donation.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final r = _reviews[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  r.reviewerName ?? 'Verified Patient / Seeker',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < r.rating ? Icons.star : Icons.star_border,
                                      color: const Color(0xFFEAB308),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              r.reviewText ?? 'Completed voluntary blood donation on time.',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
