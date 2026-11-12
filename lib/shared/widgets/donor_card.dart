import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../models/donor_profile.dart';
import 'blood_group_badge.dart';

class DonorCard extends StatelessWidget {
  final DonorProfile donor;
  final VoidCallback onTap;
  final VoidCallback onRequestContact;

  const DonorCard({
    super.key,
    required this.donor,
    required this.onTap,
    required this.onRequestContact,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = donor.availabilityStatus == 'available';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: donor.isVerified ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          width: donor.isVerified ? 1.5 : 1,
        ),
      ),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blood Group Badge
                  BloodGroupBadge(
                    bloodGroup: donor.bloodGroup,
                    fontSize: 16,
                    isLarge: true,
                  ),
                  const SizedBox(width: 14),
                  // Donor Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                donor.fullName ?? 'Voluntary Donor',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (donor.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF16A34A),
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          donor.donorIdNumber,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${donor.district ?? 'Bangladesh'}${donor.upazila != null ? ', ${donor.upazila}' : ''}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            if (donor.distanceKm != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: donor.distanceKm! <= 5.0
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${donor.distanceKm} km',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: donor.distanceKm! <= 5.0
                                        ? const Color(0xFF15803D)
                                        : Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.8),
              // Footer: Availability Status + Action Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAvailable
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEAB308),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAvailable
                            ? 'Available to Donate'
                            : 'In Rest Period (90d)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isAvailable
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  ${donor.totalVerifiedDonations} donations',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: isAvailable ? onRequestContact : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      backgroundColor: AppConfig.primaryColor,
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Request Contact',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
