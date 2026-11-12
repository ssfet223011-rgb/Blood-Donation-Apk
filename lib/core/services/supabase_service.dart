import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
  }

  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;
  static String? get currentUserId => currentUser?.id;

  static Stream<AuthState> get authStateStream => client.auth.onAuthStateChange;

  /// Helper to safely invoke PostGIS nearby donor search RPC
  static Future<List<dynamic>> searchNearbyDonors({
    String? bloodGroup,
    double? latitude,
    double? longitude,
    double maxRadiusKm = 50.0,
    String? division,
    String? district,
    String? upazila,
    bool availabilityOnly = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await client.rpc('search_nearby_donors', params: {
      'p_blood_group': bloodGroup,
      'p_latitude': latitude,
      'p_longitude': longitude,
      'p_max_radius_km': maxRadiusKm,
      'p_division': division,
      'p_district': district,
      'p_upazila': upazila,
      'p_availability_only': availabilityOnly,
      'p_limit': limit,
      'p_offset': offset,
    });
    return (response as List<dynamic>?) ?? [];
  }

  /// Emergency donor matching RPC
  static Future<int> matchEmergencyDonors({
    required String bloodRequestId,
    int maxDonors = 20,
  }) async {
    final response = await client.rpc('match_emergency_donors', params: {
      'p_blood_request_id': bloodRequestId,
      'p_max_donors': maxDonors,
    });
    return (response as int?) ?? 0;
  }

  /// Digital ID Verification RPC (Used by QR code scanner)
  static Future<Map<String, dynamic>?> verifyDonorId(String donorIdNumber) async {
    final response = await client.rpc('verify_donor_id', params: {
      'p_donor_id_number': donorIdNumber.trim().toUpperCase(),
    });
    final list = response as List<dynamic>?;
    if (list != null && list.isNotEmpty) {
      return Map<String, dynamic>.from(list.first as Map);
    }
    return null;
  }
}
