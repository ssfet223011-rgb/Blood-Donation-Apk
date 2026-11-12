import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/supabase_service.dart';
import '../models/contact_request_model.dart';

class ContactConsentState {
  final List<ContactRequestModel> incomingRequests;
  final List<ContactRequestModel> outgoingRequests;
  final bool isLoading;
  final String? errorMessage;

  ContactConsentState({
    this.incomingRequests = const [],
    this.outgoingRequests = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ContactConsentState copyWith({
    List<ContactRequestModel>? incomingRequests,
    List<ContactRequestModel>? outgoingRequests,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ContactConsentState(
      incomingRequests: incomingRequests ?? this.incomingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ContactConsentNotifier extends StateNotifier<ContactConsentState> {
  ContactConsentNotifier() : super(ContactConsentState());

  Future<void> fetchRequests({required String userId, String? donorId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. Outgoing requests sent by this user
      final outRes = await SupabaseService.client
          .from('contact_requests')
          .select('*, donor_profiles:donor_id(donor_id_number, blood_group, profiles:user_id(full_name, phone))')
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      final outList = (outRes as List<dynamic>).map((item) {
        final dp = item['donor_profiles'] as Map<String, dynamic>?;
        final prof = dp?['profiles'] as Map<String, dynamic>?;
        final map = Map<String, dynamic>.from(item);
        map['donor_name'] = prof?['full_name'];
        // Phone number is only provided if approved!
        if (item['status'] == 'approved') {
          map['donor_phone'] = prof?['phone'];
        }
        return ContactRequestModel.fromJson(map);
      }).toList();

      // 2. Incoming requests addressed to this donor (if user is a donor)
      List<ContactRequestModel> inList = [];
      if (donorId != null) {
        final inRes = await SupabaseService.client
            .from('contact_requests')
            .select('*, profiles:requester_id(full_name, phone)')
            .eq('donor_id', donorId)
            .order('created_at', ascending: false);

        inList = (inRes as List<dynamic>).map((item) {
          final prof = item['profiles'] as Map<String, dynamic>?;
          final map = Map<String, dynamic>.from(item);
          map['requester_name'] = prof?['full_name'];
          return ContactRequestModel.fromJson(map);
        }).toList();
      }

      state = state.copyWith(
        incomingRequests: inList,
        outgoingRequests: outList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> sendContactRequest({
    required String requesterId,
    required String donorId,
    String? bloodRequestId,
    String? reason,
  }) async {
    try {
      await SupabaseService.client.from('contact_requests').insert({
        'requester_id': requesterId,
        'donor_id': donorId,
        'blood_request_id': bloodRequestId,
        'request_reason': reason,
        'status': 'pending',
      });
      return true;
    } catch (e) {
      print('Error sending contact request: $e');
      return false;
    }
  }

  Future<bool> approveRequest(String requestId) async {
    try {
      final res = await SupabaseService.client.rpc(
        'approve_contact_request',
        params: {'p_contact_request_id': requestId},
      );
      return res['success'] == true;
    } catch (e) {
      print('Error approving contact request: $e');
      return false;
    }
  }

  Future<bool> declineRequest(String requestId) async {
    try {
      await SupabaseService.client
          .from('contact_requests')
          .update({'status': 'declined', 'declined_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final contactConsentProvider =
    StateNotifierProvider<ContactConsentNotifier, ContactConsentState>((ref) {
  return ContactConsentNotifier();
});
