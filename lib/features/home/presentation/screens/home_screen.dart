import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/shared/services/auth_service.dart';

import 'passenger_home_screen.dart';
import '../../../driver/presentation/screens/driver_home_screen.dart';
import '../../../conductor/presentation/screens/conductor_home_screen.dart';
import '../../../admin/presentation/screens/admin_portal_screen.dart';
import '../../../admin/presentation/screens/super_admin_portal_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final activeRole = user.role;

    Widget homeBody;
    switch (activeRole) {
      case UserRole.driver:
        homeBody = const DriverHomeScreen();
        break;
      case UserRole.conductor:
        homeBody = const ConductorHomeScreen();
        break;
      case UserRole.admin:
        homeBody = const AdminPortalScreen();
        break;
      case UserRole.superAdmin:
        homeBody = const SuperAdminPortalScreen();
        break;
      case UserRole.passenger:
        homeBody = const PassengerHomeScreen();
    }

    return Scaffold(
      body: homeBody,
    );
  }
}
