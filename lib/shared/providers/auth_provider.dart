import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/security/security_vault.dart';
import '../../core/services/supabase_service.dart';
import '../models/user_profile.dart';

enum AuthStatus { initial, unauthenticated, authenticating, authenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final UserProfile? profile;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.profile,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserProfile? profile,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial()) {
    _init();
  }

  void _init() {
    final current = SupabaseService.currentUser;
    if (current != null) {
      state = state.copyWith(status: AuthStatus.authenticated, user: current);
      loadUserProfile(current.id);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }

    SupabaseService.authStateStream.listen((event) {
      final session = event.session;
      if (session != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: session.user);
        loadUserProfile(session.user.id);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null, profile: null);
      }
    });
  }

  Future<void> loadUserProfile(String userId) async {
    try {
      final res = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      final rolesRes = await SupabaseService.client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId);

      final roles = (rolesRes as List<dynamic>?)
              ?.map((r) => r['role'].toString())
              .toList() ??
          ['registered_user'];

      if (res != null) {
        final profile = UserProfile.fromJson(res, roles: roles);
        state = state.copyWith(profile: profile);
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final res = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.session != null) {
        await SecurityVault.saveAuthTokens(
          accessToken: res.session!.accessToken,
          refreshToken: res.session!.refreshToken ?? '',
          userId: res.user!.id,
        );
        state = state.copyWith(status: AuthStatus.authenticated, user: res.user);
        await loadUserProfile(res.user!.id);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String division,
    required String district,
    String? bloodGroup,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final res = await SupabaseService.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'division': division,
          'district': district,
          if (bloodGroup != null) 'blood_group': bloodGroup,
        },
      );

      final user = res.user;
      if (user != null) {
        if (res.session != null) {
          try {
            await SupabaseService.client.from('profiles').upsert({
              'id': user.id,
              'full_name': fullName.trim(),
              'phone': phone.trim(),
              'division': division,
              'district': district,
              'blood_group': bloodGroup,
            });

            await SupabaseService.client.from('user_roles').upsert({
              'user_id': user.id,
              'role': 'registered_user',
            });
          } catch (e) {
            print('Profile insert info: $e');
          }

          state = state.copyWith(status: AuthStatus.authenticated, user: user);
          await loadUserProfile(user.id);
          return true;
        } else {
          // Supabase project requires email confirmation
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: 'অ্যাকাউন্ট তৈরি হয়েছে! আপনার ইমেইল কনফার্ম করুন অথবা লগইন করুন।',
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
    await SecurityVault.clearAuth();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
