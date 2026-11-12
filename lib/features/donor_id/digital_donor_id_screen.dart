import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/config/app_config.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/donor_profile_provider.dart';
import '../../shared/widgets/blood_group_badge.dart';

class DigitalDonorIdScreen extends ConsumerStatefulWidget {
  const DigitalDonorIdScreen({super.key});

  @override
  ConsumerState<DigitalDonorIdScreen> createState() => _DigitalDonorIdScreenState();
}

class _DigitalDonorIdScreenState extends ConsumerState<DigitalDonorIdScreen> {
  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      ref.read(donorProfileProvider.notifier).loadDonorProfile(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorState = ref.watch(donorProfileProvider);
    final user = ref.watch(authProvider).profile;
    final donor = donorState.donor;

    if (donorState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Digital Donor Card')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (donor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Digital Donor Card')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.badge_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No Digital Donor Card Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Register as a voluntary donor to generate your official Bangladesh Digital Donor ID.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push('/donor-registration'),
                  child: const Text('Register as Donor'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Secure Verification URL for QR code (contains ONLY public donor_id_number)
    final verificationUrl = '${AppConfig.verificationBaseUrl}/${donor.donorIdNumber}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Donor Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Another Card',
            onPressed: () => context.push('/scan-donor-id'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // PREMIUM DIGITAL DONOR CARD
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E293B),
                    const Color(0xFF0F172A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle water drop watermark
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.water_drop,
                      size: 180,
                      color: Colors.white.withOpacity(0.03),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppConfig.primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.water_drop, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'BLOODBOND BANGLADESH',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      'NATIONAL DONOR REGISTRY',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 9,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: donor.isVerified
                                    ? const Color(0xFF16A34A).withOpacity(0.2)
                                    : Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: donor.isVerified
                                      ? const Color(0xFF16A34A)
                                      : Colors.amber,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    donor.isVerified ? Icons.verified : Icons.hourglass_top,
                                    size: 12,
                                    color: donor.isVerified
                                        ? const Color(0xFF4ADE80)
                                        : Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    donor.isVerified ? 'VERIFIED' : 'ACTIVE',
                                    style: TextStyle(
                                      color: donor.isVerified
                                          ? const Color(0xFF4ADE80)
                                          : Colors.amber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Donor Profile Details
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppConfig.primaryColor,
                              child: Text(
                                (user?.fullName ?? 'D').substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? 'Voluntary Donor',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${user?.district ?? 'Bangladesh'} Division',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    donor.donorIdNumber,
                                    style: const TextStyle(
                                      color: Color(0xFF38BDF8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            BloodGroupBadge(
                              bloodGroup: donor.bloodGroup,
                              fontSize: 18,
                              isLarge: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 12),

                        // Footer: Verified Count & Scannable QR Code
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'VERIFIED DONATIONS',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${donor.totalVerifiedDonations}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  donor.verificationBadge.replaceAll('_', ' ').toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFFA78BFA),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),

                            // QR Code
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: QrImageView(
                                data: verificationUrl,
                                version: QrVersions.auto,
                                size: 76,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card Security Explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 18, color: Color(0xFF16A34A)),
                      SizedBox(width: 8),
                      Text(
                        'Secure QR Verification Standard',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This digital credential does not leak passwords, NIDs, phone numbers, or exact coordinates. Hospital staff scan the QR code to confirm blood group and verified donation records.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
