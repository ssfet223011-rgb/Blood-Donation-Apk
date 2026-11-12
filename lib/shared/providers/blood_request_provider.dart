import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/supabase_service.dart';
import '../models/blood_request.dart';

class BloodRequestState {
  final List<BloodRequest> activeRequests;
  final List<BloodRequest> myRequests;
  final bool isLoading;
  final String? errorMessage;

  BloodRequestState({
    this.activeRequests = const [],
    this.myRequests = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BloodRequestState copyWith({
    List<BloodRequest>? activeRequests,
    List<BloodRequest>? myRequests,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BloodRequestState(
      activeRequests: activeRequests ?? this.activeRequests,
      myRequests: myRequests ?? this.myRequests,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BloodRequestNotifier extends StateNotifier<BloodRequestState> {
  BloodRequestNotifier() : super(BloodRequestState()) {
    fetchActiveRequests();
  }

  Future<void> fetchActiveRequests() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await SupabaseService.client
          .from('blood_requests')
          .select()
          .inFilter('status', ['submitted', 'active', 'matching_donors', 'donor_responses'])
          .order('urgency_level', ascending: false)
          .order('created_at', ascending: false)
          .limit(50);

      final list = (res as List<dynamic>)
          .map((item) => BloodRequest.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      state = state.copyWith(activeRequests: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchMyRequests(String userId) async {
    try {
      final res = await SupabaseService.client
          .from('blood_requests')
          .select()
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      final list = (res as List<dynamic>)
          .map((item) => BloodRequest.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      state = state.copyWith(myRequests: list);
    } catch (e) {
      print('Error fetching user requests: $e');
    }
  }

  Future<bool> createBloodRequest(BloodRequest request) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await SupabaseService.client
          .from('blood_requests')
          .insert(request.toJson())
          .select()
          .single();

      final newRequest = BloodRequest.fromJson(res);

      // If Emergency, trigger automated PostGIS matching
      if (newRequest.isEmergency) {
        await SupabaseService.matchEmergencyDonors(
          bloodRequestId: newRequest.id,
          maxDonors: 25,
        );
      }

      await fetchActiveRequests();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> respondToRequest({
    required String bloodRequestId,
    required String donorId,
    required String response,
    String? notes,
  }) async {
    try {
      await SupabaseService.client.from('donor_responses').upsert({
        'blood_request_id': bloodRequestId,
        'donor_id': donorId,
        'response': response,
        'notes': notes,
        'responded_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error responding to request: $e');
      return false;
    }
  }
}

final bloodRequestProvider =
    StateNotifierProvider<BloodRequestNotifier, BloodRequestState>((ref) {
  return BloodRequestNotifier();
});
