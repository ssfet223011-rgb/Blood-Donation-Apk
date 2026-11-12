import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/login_screen.dart';
import '../../features/authentication/password_reset_screen.dart';
import '../../features/authentication/register_screen.dart';
import '../../features/authentication/welcome_screen.dart';
import '../../features/blood_request/create_blood_request_screen.dart';
import '../../features/blood_request/request_tracking_screen.dart';
import '../../features/contact_consent/consent_management_screen.dart';
import '../../features/donation/donation_history_screen.dart';
import '../../features/donor/availability_review_screen.dart';
import '../../features/donor/donor_registration_screen.dart';
import '../../features/donor_id/digital_donor_id_screen.dart';
import '../../features/donor_id/scan_donor_id_screen.dart';
import '../../features/donor_search/donor_details_screen.dart';
import '../../features/donor_search/find_donors_screen.dart';
import '../../features/donor_search/map_search_screen.dart';
import '../../features/home/main_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/organizations/organizations_directory_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../shared/models/donor_profile.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/password-reset',
      builder: (context, state) => const PasswordResetScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final tabIndex = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
        return MainScreen(initialIndex: tabIndex);
      },
    ),
    GoRoute(
      path: '/find-donors',
      builder: (context, state) => const FindDonorsScreen(),
    ),
    GoRoute(
      path: '/map-search',
      builder: (context, state) => const MapSearchScreen(),
    ),
    GoRoute(
      path: '/donor-details/:id',
      builder: (context, state) {
        final extra = state.extra as DonorProfile?;
        if (extra != null) {
          return DonorDetailsScreen(donor: extra);
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Donor Details')),
          body: const Center(child: Text('Donor record not available')),
        );
      },
    ),
    GoRoute(
      path: '/donor-registration',
      builder: (context, state) => const DonorRegistrationScreen(),
    ),
    GoRoute(
      path: '/digital-donor-id',
      builder: (context, state) => const DigitalDonorIdScreen(),
    ),
    GoRoute(
      path: '/scan-donor-id',
      builder: (context, state) => const ScanDonorIdScreen(),
    ),
    // Deep linking for QR verification: /verify/:id
    GoRoute(
      path: '/verify/:id',
      builder: (context, state) => const ScanDonorIdScreen(),
    ),
    GoRoute(
      path: '/create-request',
      builder: (context, state) => const CreateBloodRequestScreen(),
    ),
    GoRoute(
      path: '/request-tracking/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return RequestTrackingScreen(requestId: id);
      },
    ),
    GoRoute(
      path: '/donation-history',
      builder: (context, state) => const DonationHistoryScreen(),
    ),
    GoRoute(
      path: '/availability-review',
      builder: (context, state) => const AvailabilityReviewScreen(),
    ),
    GoRoute(
      path: '/consent-management',
      builder: (context, state) => const ConsentManagementScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/organizations',
      builder: (context, state) => const OrganizationsDirectoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
