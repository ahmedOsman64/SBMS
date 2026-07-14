import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/localization/localization_provider.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/widgets/passenger_nav_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;
    final isDarkScaffold = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkScaffold ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.tr('profile')),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pAll16,
        child: Column(
          children: [
            AppSpacing.gapH24,
            // User Avatar and basic profile headers
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 64,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  AppSpacing.gapH16,
                  Text(
                    user?.fullName ?? 'Somali Commuter',
                    style: AppTypography.h3,
                  ),
                  AppSpacing.gapH4,
                  Text(
                    user?.email ?? 'commuter@somali.so',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            AppSpacing.gapH32,

            // Profile info items list
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge_rounded, color: AppColors.primaryBlue),
                    title: const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.08),
                        borderRadius: AppSpacing.radiusCircular,
                      ),
                      child: Text(
                        user?.role.label ?? 'Passenger',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppColors.primaryBlue),
                    title: const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(
                      user?.phoneNumber ?? 'Not Set',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH24,

            // Action options
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.history_rounded, color: AppColors.primaryBlue),
                    title: const Text('Travel History'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/travel-history'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: AppColors.primaryBlue),
                    title: const Text('Help Center'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/help-center'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined, color: AppColors.primaryBlue),
                    title: const Text('Send Feedback'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/feedback'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined, color: AppColors.primaryBlue),
                    title: Text(context.tr('settings')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const PassengerNavBar(currentIndex: 3),
    );
  }
}
