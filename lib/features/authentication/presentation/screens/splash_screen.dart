import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startInitialization();
  }

  Future<void> _startInitialization() async {
    try {
      // Mimic database check and logo animations
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      bool isOnboarded = false;
      try {
        if (Hive.isBoxOpen(AppConstants.hiveSettingsBox)) {
          final settingsBox = Hive.box(AppConstants.hiveSettingsBox);
          isOnboarded = settingsBox.get(AppConstants.keyIsOnboarded, defaultValue: false) as bool;
        }
      } catch (e) {
        debugPrint('Hive box check error in splash: $e');
      }

      AppUser? user;
      try {
        final authState = ref.read(authNotifierProvider);
        user = authState.valueOrNull;
      } catch (e) {
        debugPrint('Auth state read error in splash: $e');
      }

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!isOnboarded) {
            context.go('/onboarding');
          } else if (user != null) {
            context.go(user.role.dashboardRoute);
          } else {
            context.go('/login');
          }
        });
      }
    } catch (e) {
      debugPrint('Error in splash initialization: $e');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/login');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppSpacing.radiusXLarge,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus_filled_rounded,
                color: AppColors.white,
                size: 50.0,
              ),
            ),
            AppSpacing.gapH24,
            Text(
              'SOMALI SMART BUS',
              style: AppTypography.h2.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                letterSpacing: 2,
              ),
            ),
            AppSpacing.gapH8,
            Text(
              'Safari Sugan & Fudud',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            AppSpacing.gapH48,
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
