import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../shared/models/donor_profile.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/contact_consent_provider.dart';
import '../../shared/widgets/blood_group_badge.dart';
import '../contact_consent/contact_request_dialog.dart';

class DonorDetailsScreen extends ConsumerWidget {
  final DonorProfile donor;

  const DonorDetailsScreen({super.key, required this.donor});

  void _showContactDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) {
      context.push('/login');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => ContactRequestDialog(
        donor: donor,
        onSubmit: (reason, bloodRequestId) async {
          final success = await ref
              .read(contactConsentProvider.notifier)
              .sendContactRequest(
                requesterId: user.id,
                donorId: donor.id,
                bloodRequestId: bloodRequestId,
                reason: reason,
              );
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact request submitted! Waiting for donor approval.'),
                backgroundColor: Color(0xFF16A34A),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(donor.donorIdNumber)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Donor Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppConfig.primaryColor.withOpacity(0.1),
                    child: Text(
                      (donor.fullName ?? 'D').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppConfig.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        donor.fullName ?? 'Voluntary Donor',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      if (donor.isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Color(0xFF16A34A), size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    donor.donorIdNumber,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  BloodGroupBadge(bloodGroup: donor.bloodGroup, isLarge: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Verified Donations',
                    '${donor.totalVerifiedDonations}',
                    Icons.favorite,
                    const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Rating',
                    '${donor.avgRating.toStringAsFixed(1)} ★',
                    Icons.star,
                    const Color(0xFFEAB308),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Location',
                    donor.district ?? 'Bangladesh',
                    Icons.location_on,
                    const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Badge Tier',
                    donor.verificationBadge.replaceAll('_', ' ').toUpperCase(),
                    Icons.workspace_premium,
                    const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Privacy Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: Color(0xFF0D1B2A), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Privacy Protection Policy',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The donor\'s exact home GPS location and personal mobile number are encrypted and hidden. Request consent below to initiate contact.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: donor.isAvailable ? () => _showContactDialog(context, ref) : null,
                icon: const Icon(Icons.send_outlined),
                label: Text(
                  donor.isAvailable
                      ? 'Request Contact Permission'
                      : 'Donor Currently in Rest Period',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
