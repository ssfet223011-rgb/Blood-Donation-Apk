import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/bangladesh_locations.dart';
import '../../shared/models/blood_request.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/blood_request_provider.dart';
import '../../shared/providers/donor_search_provider.dart';
import '../../shared/widgets/blood_group_badge.dart';
import '../../shared/widgets/emergency_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final requestState = ref.watch(bloodRequestProvider);
    final user = authState.profile;

    final emergencyRequests =
        requestState.activeRequests.where((r) => r.isEmergency).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConfig.appName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  user != null ? '${user.district}, Bangladesh' : 'Bangladesh Network',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan Donor ID',
            onPressed: () => context.push('/scan-donor-id'),
          ),
          IconButton(
            icon: const Icon(Icons.phone_in_talk, color: Color(0xFFDC2626)),
            tooltip: 'Emergency Hotline 999',
            onPressed: () => launchUrl(Uri.parse('tel:${AppConfig.emergencyHotline}')),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(bloodRequestProvider.notifier).fetchActiveRequests();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Emergency Banner (If any emergency active requests exist)
              if (emergencyRequests.isNotEmpty) ...[
                EmergencyAlertBanner(
                  title: '🚨 ${emergencyRequests.length} Emergency Blood Requests',
                  message:
                      'Matching donors needed immediately in ${emergencyRequests.first.district}. Tap to review.',
                  onTap: () => context.push('/request-tracking/${emergencyRequests.first.id}'),
                ),
              ],

              // 2. Quick Action Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConfig.primaryColor,
                      const Color(0xFF8E0000),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppConfig.primaryColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Need Blood Urgently?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '24/7 LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Post a verified blood request and alert matching donors within 5 km immediately.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.push('/create-request'),
                          icon: const Icon(Icons.add_alert, color: Color(0xFFC62828), size: 18),
                          label: const Text(
                            'Request Blood',
                            style: TextStyle(
                              color: Color(0xFFC62828),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/digital-donor-id'),
                          icon: const Icon(Icons.badge, color: Colors.white, size: 18),
                          label: const Text(
                            'My Donor ID',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white, width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Quick Blood Group Filter Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Search by Blood Group',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => context.push('/find-donors'),
                      child: const Text('All Filters'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: BangladeshLocations.bloodGroups.length,
                  itemBuilder: (context, index) {
                    final group = BangladeshLocations.bloodGroups[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          ref.read(donorSearchProvider.notifier).setBloodGroup(group);
                          context.push('/find-donors');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: BloodGroupBadge(bloodGroup: group, fontSize: 14),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 4. Active Blood Requests
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Urgent Blood Requests',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${requestState.activeRequests.length} active',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (requestState.isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else if (requestState.activeRequests.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No active blood requests currently needed.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requestState.activeRequests.take(5).length,
                  itemBuilder: (context, index) {
                    final req = requestState.activeRequests[index];
                    return _buildRequestCard(context, req);
                  },
                ),
              ],

              const SizedBox(height: 24),

              // 5. Bangladesh Quick Hotline & Red Crescent Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.health_and_safety, color: Color(0xFFC62828), size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Red Crescent Blood Center',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            'National Blood Transfusion Hotline',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => launchUrl(Uri.parse('tel:${AppConfig.nationalBloodCenterPhone}')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.secondaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Call', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, BloodRequest req) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: req.isEmergency ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: req.isEmergency ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: BloodGroupBadge(bloodGroup: req.bloodGroup, isLarge: true),
        title: Row(
          children: [
            Expanded(
              child: Text(
                req.patientName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (req.isEmergency) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'EMERGENCY',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.local_hospital_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    req.hospitalName,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${req.district} • ${req.unitsNeeded} Units needed',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => context.push('/request-tracking/${req.id}'),
      ),
    );
  }
}
