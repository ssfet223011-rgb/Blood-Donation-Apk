import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/config/app_config.dart';
import '../../shared/models/donor_profile.dart';
import '../../shared/providers/donor_search_provider.dart';

class MapSearchScreen extends ConsumerStatefulWidget {
  const MapSearchScreen({super.key});

  @override
  ConsumerState<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends ConsumerState<MapSearchScreen> {
  final MapController _mapController = MapController();
  DonorProfile? _selectedDonor;

  // Center of Bangladesh (approx Dhaka)
  final LatLng _initialCenter = const LatLng(23.8103, 90.4125);

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(donorSearchProvider);

    // Build markers using privacy-safe approximate coordinates
    final markers = searchState.donors.where((d) => d.approxLatitude != null && d.approxLongitude != null).map((donor) {
      final isSelected = _selectedDonor?.id == donor.id;
      return Marker(
        point: LatLng(donor.approxLatitude!, donor.approxLongitude!),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedDonor = donor);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0D1B2A) : AppConfig.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                donor.bloodGroup,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Donors Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              ref.read(donorSearchProvider.notifier).useCurrentLocation();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 7.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bloodbond.bangladesh',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Privacy Disclaimer Tag
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: Color(0xFF16A34A), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pins represent approximate areas (~1km) for donor privacy protection.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Selected Donor Preview Card
          if (_selectedDonor != null) ...[
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedDonor!.bloodGroup,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedDonor!.fullName ?? 'Voluntary Donor',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            Text(
                              '${_selectedDonor!.district} • ${_selectedDonor!.totalVerifiedDonations} donations',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.push(
                            '/donor-details/${_selectedDonor!.id}',
                            extra: _selectedDonor,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text('View', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
