import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../shared/models/contact_request_model.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/contact_consent_provider.dart';
import '../../shared/providers/donor_profile_provider.dart';
import '../../shared/widgets/empty_state.dart';

class ConsentManagementScreen extends ConsumerStatefulWidget {
  const ConsentManagementScreen({super.key});

  @override
  ConsumerState<ConsentManagementScreen> createState() => _ConsentManagementScreenState();
}

class _ConsentManagementScreenState extends ConsumerState<ConsentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refresh();
  }

  void _refresh() {
    final user = ref.read(authProvider).user;
    final donor = ref.read(donorProfileProvider).donor;
    if (user != null) {
      ref.read(contactConsentProvider.notifier).fetchRequests(
            userId: user.id,
            donorId: donor?.id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final consentState = ref.watch(contactConsentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Permissions & Privacy'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConfig.primaryColor,
          labelColor: AppConfig.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Received (${consentState.incomingRequests.length})'),
            Tab(text: 'Sent (${consentState.outgoingRequests.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Incoming Requests (Received by Donor)
          consentState.incomingRequests.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.shield_outlined,
                  title: 'No Pending Contact Requests',
                  message: 'When patients or blood seekers request your contact number, they appear here for your explicit approval.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: consentState.incomingRequests.length,
                  itemBuilder: (context, index) {
                    final req = consentState.incomingRequests[index];
                    return _buildIncomingCard(req);
                  },
                ),

          // 2. Outgoing Requests (Sent by Seeker)
          consentState.outgoingRequests.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.outbox,
                  title: 'No Outgoing Contact Requests',
                  message: 'When you find a donor and request their contact details, your authorization requests will appear here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: consentState.outgoingRequests.length,
                  itemBuilder: (context, index) {
                    final req = consentState.outgoingRequests[index];
                    return _buildOutgoingCard(req);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildIncomingCard(ContactRequestModel req) {
    final isPending = req.isPending;

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
                  req.requesterName ?? 'Blood Seeker',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                _buildStatusPill(req.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              req.requestReason ?? 'Requires urgent voluntary blood donor contact.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final ok = await ref
                            .read(contactConsentProvider.notifier)
                            .approveRequest(req.id);
                        if (ok) _refresh();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                      child: const Text('Approve (48h)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final ok = await ref
                            .read(contactConsentProvider.notifier)
                            .declineRequest(req.id);
                        if (ok) _refresh();
                      },
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingCard(ContactRequestModel req) {
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
                  req.donorName ?? 'Voluntary Donor',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                _buildStatusPill(req.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              req.isApproved
                  ? 'Consent Granted! You may contact this donor directly:'
                  : 'Waiting for donor approval. Phone number remains protected.',
              style: TextStyle(
                fontSize: 13,
                color: req.isApproved ? const Color(0xFF16A34A) : Colors.grey.shade600,
                fontWeight: req.isApproved ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (req.isApproved && req.donorPhone != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      req.donorPhone!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse('tel:${req.donorPhone}')),
                      icon: const Icon(Icons.call, size: 16),
                      label: const Text('Call Donor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case 'declined':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
