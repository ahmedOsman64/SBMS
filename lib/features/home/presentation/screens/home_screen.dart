import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/services/auth_service.dart';

import 'passenger_home_screen.dart';
import '../../../driver/presentation/screens/driver_home_screen.dart';
import '../../../conductor/presentation/screens/conductor_home_screen.dart';
import '../../../admin/presentation/screens/admin_portal_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  UserRole? _debugOverrideRole;

  void _showRoleSwitcherBottomSheet(BuildContext context, UserRole currentRole) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final activeRole = _debugOverrideRole ?? currentRole;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Debug Portal Switcher',
                      style: AppTypography.h3.copyWith(color: AppColors.primaryBlue),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Text(
                  'Switch portals instantly for local testing without logging out.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                AppSpacing.gapH20,
                ...UserRole.values.map((role) {
                  final isSelected = activeRole == role;
                  return ListTile(
                    leading: Icon(
                      _getRoleIcon(role),
                      color: isSelected ? AppColors.primaryBlue : Colors.grey,
                    ),
                    title: Text(
                      role.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primaryBlue : null,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue)
                        : null,
                    onTap: () {
                      setState(() {
                        _debugOverrideRole = role;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to ${role.label} Viewport'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  );
                }),
                AppSpacing.gapH8,
                if (_debugOverrideRole != null)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _debugOverrideRole = null;
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('Reset to Auth Profile Default'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.passenger:
        return Icons.people_alt_rounded;
      case UserRole.driver:
        return Icons.drive_eta_rounded;
      case UserRole.conductor:
        return Icons.badge_rounded;
      case UserRole.admin:
      case UserRole.superAdmin:
        return Icons.admin_panel_settings_rounded;
    }
  }

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

    final activeRole = _debugOverrideRole ?? user.role;

    Widget homeBody;
    switch (activeRole) {
      case UserRole.driver:
        homeBody = const DriverHomeScreen();
        break;
      case UserRole.conductor:
        homeBody = const ConductorHomeScreen();
        break;
      case UserRole.admin:
      case UserRole.superAdmin:
        homeBody = const AdminPortalScreen();
        break;
      case UserRole.passenger:
        homeBody = const PassengerHomeScreen();
    }

    return Scaffold(
      body: homeBody,
      // Debug floating action button to allow switching views quickly
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: AppColors.accentGold,
        foregroundColor: Colors.white,
        onPressed: () => _showRoleSwitcherBottomSheet(context, user.role),
        tooltip: 'Switch Portal Roles',
        child: const Icon(Icons.developer_mode_rounded),
      ),
    );
  }
}
