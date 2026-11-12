import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/models/blood_request.dart';
import '../../shared/providers/blood_request_provider.dart';
import '../../shared/providers/donor_profile_provider.dart';
import '../../shared/widgets/blood_group_badge.dart';

class RequestTrackingScreen extends ConsumerStatefulWidget {
  final String requestId;

  const RequestTrackingScreen({super.key, required this.requestId});

  @override
  ConsumerState<RequestTrackingScreen> createState() => _RequestTrackingScreenState();
}

class _RequestTrackingScreenState extends ConsumerState<RequestTrackingScreen> {
  BloodRequest? _request;
  List<Map<String, dynamic>> _responses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final reqRes = await SupabaseService.client
          .from('blood_requests')
          .select()
          .eq('id', widget.requestId)
          .maybeSingle();

      if (reqRes != null) {
        _request = BloodRequest.fromJson(reqRes);

        final respRes = await SupabaseService.client
            .from('donor_responses')
            .select('*, donor_profiles:donor_id(donor_id_number, blood_group, profiles:user_id(full_name, phone))')
            .eq('blood_request_id', widget.requestId);

        _responses = (respRes as List<dynamic>?)
                ?.map((item) => Map<String, dynamic>.from(item as Map))
                .toList() ??
            [];
      }
    } catch (e) {
      print('Error fetching request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendDonorResponse(String responseType) async {
    final donor = ref.read(donorProfileProvider).donor;
    if (donor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be a registered donor to respond.')),
      );
      return;
    }

    final success = await ref.read(bloodRequestProvider.notifier).respondToRequest(
          bloodRequestId: widget.requestId,
          donorId: donor.id,
          response: responseType,
        );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Response sent: ${responseType.toUpperCase()}'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      await _fetchDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Status')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Status')),
        body: const Center(child: Text('Blood request not found')),
      );
    }

    final req = _request!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Request Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: req.isEmergency ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
                  width: req.isEmergency ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BloodGroupBadge(bloodGroup: req.bloodGroup, isLarge: true),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: req.isEmergency
                              ? const Color(0xFFDC2626)
                              : AppConfig.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          req.status.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    req.patientName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${req.hospitalName} • ${req.district}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${req.unitsNeeded} Units Required by ${DateFormat('dd MMM yyyy').format(req.requiredDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Attendant Contact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk, color: Color(0xFF16A34A)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.contactPersonName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          req.contactPhone,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: Color(0xFF16A34A)),
                    onPressed: () => launchUrl(Uri.parse('tel:${req.contactPhone}')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Donor Action Bar (For Registered Donors)
            const Text(
              'Are you able to donate for this patient?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sendDonorResponse('interested'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Interested'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sendDonorResponse('contact_me'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Contact Me'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _sendDonorResponse('cannot_donate'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Live Donor Responses List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Matching Donor Responses',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${_responses.length} responses',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_responses.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No donor responses yet. Nearby donors have been alerted.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _responses.length,
                itemBuilder: (context, index) {
                  final resp = _responses[index];
                  final dp = resp['donor_profiles'] as Map<String, dynamic>?;
                  final prof = dp?['profiles'] as Map<String, dynamic>?;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: BloodGroupBadge(bloodGroup: dp?['blood_group'] ?? 'O+'),
                      title: Text(
                        prof?['full_name'] ?? 'Donor',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('ID: ${dp?['donor_id_number'] ?? 'N/A'}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: resp['response'] == 'cannot_donate'
                              ? Colors.grey.shade200
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (resp['response'] as String? ?? '').replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: resp['response'] == 'cannot_donate'
                                ? Colors.grey.shade700
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
