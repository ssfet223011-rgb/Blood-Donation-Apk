import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/supabase_service.dart';
import '../models/donation_record.dart';
import '../models/donor_profile.dart';

class DonorProfileState {
  final DonorProfile? donor;
  final List<DonationRecord> donations;
  final bool isLoading;
  final String? errorMessage;

  DonorProfileState({
    this.donor,
    this.donations = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DonorProfileState copyWith({
    DonorProfile? donor,
    List<DonationRecord>? donations,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DonorProfileState(
      donor: donor ?? this.donor,
      donations: donations ?? this.donations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DonorProfileNotifier extends StateNotifier<DonorProfileState> {
  DonorProfileNotifier() : super(DonorProfileState());

  Future<void> loadDonorProfile(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await SupabaseService.client
          .from('donor_profiles')
          .select('*, profiles:user_id(full_name, avatar_url, division, district, upazila, thana, local_area)')
          .eq('user_id', userId)
          .maybeSingle();

      if (res != null) {
        final profileMap = res['profiles'] as Map<String, dynamic>?;
        final merged = Map<String, dynamic>.from(res);
        if (profileMap != null) {
          merged.addAll(profileMap);
        }
        final donor = DonorProfile.fromJson(merged);
        state = state.copyWith(donor: donor, isLoading: false);
        await loadDonations(donor.id);
      } else {
        state = state.copyWith(donor: null, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadDonations(String donorId) async {
    try {
      final res = await SupabaseService.client
          .from('donations')
          .select()
          .eq('donor_id', donorId)
          .order('donation_date', ascending: false);

      final list = (res as List<dynamic>)
          .map((item) => DonationRecord.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      state = state.copyWith(donations: list);
    } catch (e) {
      print('Error loading donations: $e');
    }
  }

  Future<bool> registerAsDonor({
    required String userId,
    required String bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool hidePhone = true,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await SupabaseService.client
          .from('donor_profiles')
          .insert({
            'user_id': userId,
            'blood_group': bloodGroup,
            'emergency_contact_name': emergencyContactName,
            'emergency_contact_phone': emergencyContactPhone,
            'hide_phone_number': hidePhone,
          })
          .select()
          .single();

      await loadDonorProfile(userId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateAvailabilityStatus(String newStatus) async {
    if (state.donor == null) return false;
    try {
      await SupabaseService.client
          .from('donor_profiles')
          .update({'availability_status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', state.donor!.id);

      state = state.copyWith(
        donor: DonorProfile.fromJson({
          ...state.donor!.toJson(),
          'availability_status': newStatus,
        }),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> confirmAvailabilityReview(bool isAvailable) async {
    final status = isAvailable ? 'available' : 'temporarily_unavailable';
    return await updateAvailabilityStatus(status);
  }
}

extension DonorProfileExt on DonorProfile {
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'donor_id_number': donorIdNumber,
    'blood_group': bloodGroup,
    'is_verified': isVerified,
    'verification_badge': verificationBadge,
    'availability_status': availabilityStatus,
    'total_verified_donations': totalVerifiedDonations,
    'full_name': fullName,
    'district': district,
  };
}

final donorProfileProvider =
    StateNotifierProvider<DonorProfileNotifier, DonorProfileState>((ref) {
  return DonorProfileNotifier();
});
