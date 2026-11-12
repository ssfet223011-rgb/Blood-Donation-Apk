import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../shared/providers/donor_profile_provider.dart';

class AvailabilityReviewScreen extends ConsumerStatefulWidget {
  const AvailabilityReviewScreen({super.key});

  @override
  ConsumerState<AvailabilityReviewScreen> createState() => _AvailabilityReviewScreenState();
}

class _AvailabilityReviewScreenState extends ConsumerState<AvailabilityReviewScreen> {
  bool _feelsHealthy = false;
  bool _noRecentIllness = false;
  bool _noTattoosOrSurgeries = false;
  bool _isSubmitting = false;

  Future<void> _submitReview(bool markAvailable) async {
    setState(() => _isSubmitting = true);
    final success = await ref
        .read(donorProfileProvider.notifier)
        .confirmAvailabilityReview(markAvailable);
    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            markAvailable
                ? 'Availability updated to AVAILABLE!'
                : 'Availability updated to RESTING / MEDICAL HOLD.',
          ),
          backgroundColor:
              markAvailable ? const Color(0xFF16A34A) : const Color(0xFFD97706),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final donor = ref.watch(donorProfileProvider).donor;
    final allChecked = _feelsHealthy && _noRecentIllness && _noTattoosOrSurgeries;

    return Scaffold(
      appBar: AppBar(title: const Text('Availability Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '90-Day Post-Donation Rest Period Complete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please verify your health condition before resuming voluntary blood donations.',
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Self-Health Confirmation Checklist',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Per Bangladesh national blood transfusion policy, donors must feel healthy and uncompromised:',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),

            CheckboxListTile(
              value: _feelsHealthy,
              activeColor: AppConfig.primaryColor,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I am feeling well, rested, and not currently experiencing fatigue or dizziness.',
                style: TextStyle(fontSize: 14),
              ),
              onChanged: (v) => setState(() => _feelsHealthy = v ?? false),
            ),

            CheckboxListTile(
              value: _noRecentIllness,
              activeColor: AppConfig.primaryColor,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I have not had a fever, cough, flu, or infection in the past 14 days.',
                style: TextStyle(fontSize: 14),
              ),
              onChanged: (v) => setState(() => _noRecentIllness = v ?? false),
            ),

            CheckboxListTile(
              value: _noTattoosOrSurgeries,
              activeColor: AppConfig.primaryColor,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I have had no major surgery, dental procedure, or new tattoos in the last 6 months.',
                style: TextStyle(fontSize: 14),
              ),
              onChanged: (v) => setState(() => _noTattoosOrSurgeries = v ?? false),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!allChecked || _isSubmitting)
                    ? null
                    : () => _submitReview(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'I Am Ready & Available to Donate',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => _submitReview(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('I Need More Rest / Delay Availability'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
