import 'package:flutter/material.dart';

/// Configurable branding and environment configuration for BloodBond Bangladesh.
class AppConfig {
  // Platform Branding
  static String appName = 'BloodBond Bangladesh';
  static String tagline = 'Every Drop Connects a Life.';
  static String emergencyHotline = '999';
  static String nationalBloodCenterPhone = '+88029116563';
  static String supportEmail = 'support@bloodbond.bd';
  static String verificationBaseUrl = 'https://bloodbond.bd/verify';

  // Configurable Brand Colors
  static Color primaryColor = const Color(0xFFC62828); // Deep Blood Red
  static Color secondaryColor = const Color(0xFF0D1B2A); // Navy Blue
  static Color accentColor = const Color(0xFFE53935); // Accent Crimson
  static Color backgroundColor = const Color(0xFFFFFFFF); // Clean White
  static Color emergencyColor = const Color(0xFFD32F2F); // High Alert Red
  static Color successColor = const Color(0xFF2E7D32); // Verification Green

  // Supabase Configuration
  // Note: Anon key is client-safe with RLS. Service role key is NEVER embedded in the client!
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://udushfprexltqjbqlmro.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_kJGyf_zlH1zGHr9tYarl9w_O7NCwBzY',
  );

  // Geographic Discovery Limits (km)
  static const double searchRadiusTier1Km = 5.0;
  static const double searchRadiusTier2Km = 20.0;
  static const double searchRadiusTier3Km = 50.0;
  static const double searchRadiusMaxKm = 100.0;

  // Donation Rules
  static const int donationCooldownDays = 90;
  static const int minimumDonorAge = 18;
  static const int maximumDonorAge = 60;
  static const double minimumWeightKgMale = 50.0;
  static const double minimumWeightKgFemale = 45.0;

  /// Allows dynamic admin branding overrides at runtime
  static void updateBranding({
    String? newName,
    String? newTagline,
    Color? newPrimary,
    Color? newSecondary,
  }) {
    if (newName != null) appName = newName;
    if (newTagline != null) tagline = newTagline;
    if (newPrimary != null) primaryColor = newPrimary;
    if (newSecondary != null) secondaryColor = newSecondary;
  }
}
