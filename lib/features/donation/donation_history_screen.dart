import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/config/app_config.dart';
import '../../shared/models/donation_record.dart';
import '../../shared/providers/donor_profile_provider.dart';
import '../../shared/widgets/empty_state.dart';

class DonationHistoryScreen extends ConsumerWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donorState = ref.watch(donorProfileProvider);
    final donations = donorState.donations;
    final donor = donorState.donor;

    return Scaffold(
      appBar: AppBar(title: const Text('Donation History')),
      body: Column(
        children: [
          // Official Summary Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  'Verified Count',
                  '${donor?.totalVerifiedDonations ?? 0}',
                  AppConfig.primaryColor,
                ),
                _buildStat(
                  'Badge',
                  donor?.verificationBadge.replaceAll('_', ' ').toUpperCase() ?? 'ACTIVE',
                  const Color(0xFF7C3AED),
                ),
                _buildStat(
                  'Status',
                  donor?.isAvailable == true ? 'AVAILABLE' : 'RESTING (90d)',
                  donor?.isAvailable == true
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFB45309),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: donations.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.history,
                    title: 'No Donation Records Yet',
                    message:
                        'Your verified hospital and blood drive donations will be recorded here by medical coordinators.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: donations.length,
                    itemBuilder: (context, index) {
                      final item = donations[index];
                      return _buildDonationCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDonationCard(DonationRecord rec) {
    final isVerified = rec.isVerified;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isVerified
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isVerified ? Icons.check_circle : Icons.schedule,
                color: isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.hospitalName ?? 'Voluntary Donation',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(rec.donationDate)} • ${rec.units} Unit (${rec.donationType.replaceAll('_', ' ')})',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isVerified
                    ? const Color(0xFF16A34A).withOpacity(0.1)
                    : const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rec.verificationStatus.toUpperCase(),
                style: TextStyle(
                  color: isVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
