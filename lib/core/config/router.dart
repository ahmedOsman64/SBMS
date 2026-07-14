import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/screens/onboarding_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/otp_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/driver/presentation/screens/driver_home_screen.dart';
import '../../features/conductor/presentation/screens/conductor_home_screen.dart';
import '../../features/fleet/presentation/screens/fleet_home_screen.dart';
import '../../features/admin/presentation/screens/admin_portal_screen.dart';
import '../../features/admin/presentation/screens/admin_company_screen.dart';
import '../../features/admin/presentation/screens/super_admin_portal_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/booking/presentation/screens/search_routes_screen.dart';
import '../../features/booking/presentation/screens/route_details_screen.dart';
import '../../features/booking/presentation/screens/seat_selection_screen.dart';
import '../../features/booking/presentation/screens/payment_screen.dart';
import '../../features/booking/presentation/screens/booking_confirm_screen.dart';
import '../../features/tickets/presentation/screens/ticket_history_screen.dart';
import '../../features/tickets/presentation/screens/ticket_details_screen.dart';
import '../../features/payments/presentation/screens/wallet_screen.dart';
import '../../features/profile/presentation/screens/travel_history_screen.dart';
import '../../features/settings/presentation/screens/help_center_screen.dart';
import '../../features/settings/presentation/screens/feedback_screen.dart';
import '../shared/services/auth_service.dart';
import 'constants.dart';

// Key for app navigation control
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

final routerProvider = Provider<GoRouter>((ref) {
  final navigatorKey = ref.watch(navigatorKeyProvider);
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;

      final settingsBox = Hive.box(AppConstants.hiveSettingsBox);
      final isOnboarded =
          settingsBox.get(AppConstants.keyIsOnboarded, defaultValue: false)
              as bool;

      final loc = state.matchedLocation;
      final isGoingToSplash = loc == '/';
      final isGoingToOnboarding = loc == '/onboarding';
      final isGoingToLogin = loc == '/login';
      final isGoingToRegister = loc == '/register';
      final isGoingToForgot = loc == '/forgot-password';
      final isGoingToOtp = loc == '/otp';

      final isAuthRoute = isGoingToLogin ||
          isGoingToRegister ||
          isGoingToForgot ||
          isGoingToOtp;

      // 1. Splash — let it handle itself
      if (isGoingToSplash) return null;

      // 2. Onboarding check
      if (!isOnboarded && !isGoingToOnboarding) return '/onboarding';

      // 3. Not logged in
      if (!isLoggedIn) {
        if (!isAuthRoute && !isGoingToOnboarding) return '/login';
        return null;
      }

      // 4. Logged in — redirect from auth/onboarding to role dashboard
      if (isAuthRoute || isGoingToOnboarding) {
        return user.role.dashboardRoute;
      }

      // 5. Guard privileged routes from unauthorised roles
      //    (belt-and-suspenders — the UI shouldn't show these links anyway)
      if (loc == '/super-admin' && user.role != UserRole.superAdmin) {
        return user.role.dashboardRoute;
      }
      if (loc == '/admin-portal' &&
          user.role != UserRole.admin &&
          user.role != UserRole.superAdmin) {
        return user.role.dashboardRoute;
      }
      if (loc == '/driver-home' && user.role != UserRole.driver) {
        return user.role.dashboardRoute;
      }
      if (loc == '/conductor-home' && user.role != UserRole.conductor) {
        return user.role.dashboardRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return OTPScreen(email: email);
        },
      ),

      // ── Role Dashboards ────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/driver-home',
        builder: (context, state) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/conductor-home',
        builder: (context, state) => const ConductorHomeScreen(),
      ),
      GoRoute(
        path: '/fleet-home',
        builder: (context, state) => const FleetHomeScreen(),
      ),
      GoRoute(
        path: '/admin-portal',
        builder: (context, state) => const AdminPortalScreen(),
      ),
      GoRoute(
        path: '/admin-company',
        builder: (context, state) => const AdminCompanyScreen(),
      ),
      // SuperAdmin exclusive portal
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminPortalScreen(),
      ),

      // ── Shared Routes ──────────────────────────────────────────────────────
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/booking-search',
        builder: (context, state) => const SearchRoutesScreen(),
      ),
      GoRoute(
        path: '/booking-routes-details',
        builder: (context, state) {
          final dep = state.uri.queryParameters['departure'];
          final arr = state.uri.queryParameters['arrival'];
          return RouteDetailsScreen(departure: dep, arrival: arr);
        },
      ),
      GoRoute(
        path: '/booking-seats',
        builder: (context, state) => const SeatSelectionScreen(),
      ),
      GoRoute(
        path: '/booking-payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/booking-confirmation',
        builder: (context, state) => const BookingConfirmScreen(),
      ),
      GoRoute(
        path: '/ticket-history',
        builder: (context, state) => const TicketHistoryScreen(),
      ),
      GoRoute(
        path: '/ticket-details',
        builder: (context, state) {
          final idx =
              int.tryParse(state.uri.queryParameters['index'] ?? '0') ?? 0;
          return TicketDetailsScreen(index: idx);
        },
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/travel-history',
        builder: (context, state) => const TravelHistoryScreen(),
      ),
      GoRoute(
        path: '/help-center',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
    ],
  );
});
