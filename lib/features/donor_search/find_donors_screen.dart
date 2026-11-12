import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/bangladesh_locations.dart';
import '../../shared/models/donor_profile.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/contact_consent_provider.dart';
import '../../shared/providers/donor_search_provider.dart';
import '../../shared/widgets/donor_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../contact_consent/contact_request_dialog.dart';

class FindDonorsScreen extends ConsumerStatefulWidget {
  const FindDonorsScreen({super.key});

  @override
  ConsumerState<FindDonorsScreen> createState() => _FindDonorsScreenState();
}

class _FindDonorsScreenState extends ConsumerState<FindDonorsScreen> {
  final bool _isMapView = false;

  void _showContactDialog(DonorProfile donor) {
    final user = ref.read(authProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to send a contact request.'),
          action: SnackBarAction(
            label: 'Sign In',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ContactRequestDialog(
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
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact request sent! The donor will be notified.'),
                backgroundColor: Color(0xFF16A34A),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(donorSearchProvider);
    final searchNotifier = ref.read(donorSearchProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Blood Donors'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list_alt : Icons.map_outlined),
            tooltip: _isMapView ? 'Switch to List View' : 'Switch to Map View',
            onPressed: () {
              if (!_isMapView) {
                context.push('/map-search');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // Blood Group & GPS row
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: searchState.bloodGroup,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Blood Group',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Groups')),
                          ...BangladeshLocations.bloodGroups.map(
                            (bg) => DropdownMenuItem(value: bg, child: Text(bg)),
                          ),
                        ],
                        onChanged: (val) => searchNotifier.setBloodGroup(val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        value: searchState.division,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Division',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Bangladesh')),
                          ...BangladeshLocations.divisions.map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          ),
                        ],
                        onChanged: (val) => searchNotifier.setDivision(val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                      ),
                      icon: const Icon(Icons.my_location, size: 20, color: Colors.white),
                      tooltip: 'Nearby 5km (GPS)',
                      onPressed: () => searchNotifier.useCurrentLocation(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Availability Toggle + Radius
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: searchState.availabilityOnly,
                          activeColor: AppConfig.primaryColor,
                          onChanged: (v) => searchNotifier.toggleAvailabilityOnly(v ?? true),
                        ),
                        const Text('Available Only', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      children: [5.0, 20.0, 50.0].map((radius) {
                        final isSelected = searchState.maxRadiusKm == radius;
                        return ChoiceChip(
                          label: Text('${radius.toInt()} km'),
                          selected: isSelected,
                          selectedColor: AppConfig.primaryColor.withOpacity(0.15),
                          onSelected: (_) => searchNotifier.setRadius(radius),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Donors List
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchState.donors.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.person_search_outlined,
                        title: 'No Matching Donors Found',
                        message:
                            'No voluntary donors matched your filter criteria. Try expanding the search radius or choosing another division.',
                        actionLabel: 'Reset Filters',
                        onAction: () {
                          searchNotifier.setBloodGroup(null);
                          searchNotifier.setDivision(null);
                        },
                      )
                    : RefreshIndicator(
                        onRefresh: () async => searchNotifier.searchDonors(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: searchState.donors.length,
                          itemBuilder: (context, index) {
                            final donor = searchState.donors[index];
                            return DonorCard(
                              donor: donor,
                              onTap: () => context.push('/donor-details/${donor.id}', extra: donor),
                              onRequestContact: () => _showContactDialog(donor),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
