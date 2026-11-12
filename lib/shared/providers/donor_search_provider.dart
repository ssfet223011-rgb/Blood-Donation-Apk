import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/location_service.dart';
import '../../core/services/supabase_service.dart';
import '../models/donor_profile.dart';

class DonorSearchState {
  final List<DonorProfile> donors;
  final bool isLoading;
  final String? bloodGroup;
  final String? division;
  final String? district;
  final String? upazila;
  final double? latitude;
  final double? longitude;
  final double maxRadiusKm;
  final bool availabilityOnly;
  final String? errorMessage;

  DonorSearchState({
    this.donors = const [],
    this.isLoading = false,
    this.bloodGroup,
    this.division,
    this.district,
    this.upazila,
    this.latitude,
    this.longitude,
    this.maxRadiusKm = 50.0,
    this.availabilityOnly = true,
    this.errorMessage,
  });

  DonorSearchState copyWith({
    List<DonorProfile>? donors,
    bool? isLoading,
    String? bloodGroup,
    String? division,
    String? district,
    String? upazila,
    double? latitude,
    double? longitude,
    double? maxRadiusKm,
    bool? availabilityOnly,
    String? errorMessage,
  }) {
    return DonorSearchState(
      donors: donors ?? this.donors,
      isLoading: isLoading ?? this.isLoading,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      division: division ?? this.division,
      district: district ?? this.district,
      upazila: upazila ?? this.upazila,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxRadiusKm: maxRadiusKm ?? this.maxRadiusKm,
      availabilityOnly: availabilityOnly ?? this.availabilityOnly,
      errorMessage: errorMessage,
    );
  }
}

class DonorSearchNotifier extends StateNotifier<DonorSearchState> {
  DonorSearchNotifier() : super(DonorSearchState()) {
    searchDonors();
  }

  void setBloodGroup(String? group) {
    state = state.copyWith(bloodGroup: group);
    searchDonors();
  }

  void setDivision(String? div) {
    state = state.copyWith(division: div, district: null, upazila: null);
    searchDonors();
  }

  void setDistrict(String? dist) {
    state = state.copyWith(district: dist, upazila: null);
    searchDonors();
  }

  void setRadius(double radiusKm) {
    state = state.copyWith(maxRadiusKm: radiusKm);
    searchDonors();
  }

  void toggleAvailabilityOnly(bool value) {
    state = state.copyWith(availabilityOnly: value);
    searchDonors();
  }

  Future<void> useCurrentLocation() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      state = state.copyWith(latitude: pos.latitude, longitude: pos.longitude);
      searchDonors();
    }
  }

  Future<void> searchDonors() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final rawList = await SupabaseService.searchNearbyDonors(
        bloodGroup: state.bloodGroup,
        latitude: state.latitude,
        longitude: state.longitude,
        maxRadiusKm: state.maxRadiusKm,
        division: state.division,
        district: state.district,
        upazila: state.upazila,
        availabilityOnly: state.availabilityOnly,
      );

      final donors = rawList
          .map((item) => DonorProfile.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      state = state.copyWith(donors: donors, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final donorSearchProvider =
    StateNotifierProvider<DonorSearchNotifier, DonorSearchState>((ref) {
  return DonorSearchNotifier();
});
