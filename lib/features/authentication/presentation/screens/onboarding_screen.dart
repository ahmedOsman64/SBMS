import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/localization/localization_provider.dart';
import '../../../../core/shared/widgets/buttons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingModel> _slides = [
    const OnboardingModel(
      titleKey: 'onboarding1_title',
      descKey: 'onboarding1_desc',
      icon: Icons.bookmark_add_rounded,
    ),
    const OnboardingModel(
      titleKey: 'onboarding2_title',
      descKey: 'onboarding2_desc',
      icon: Icons.map_rounded,
    ),
    const OnboardingModel(
      titleKey: 'onboarding3_title',
      descKey: 'onboarding3_desc',
      icon: Icons.admin_panel_settings_rounded,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final settingsBox = Hive.box(AppConstants.hiveSettingsBox);
    await settingsBox.put(AppConstants.keyIsOnboarded, true);
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentIndex < _slides.length - 1)
            TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                'Skip',
                style: AppTypography.button.copyWith(color: AppColors.primaryBlue),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.pAll24,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: AppSpacing.pAll24,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          slide.icon,
                          size: 100,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      AppSpacing.gapH48,
                      Text(
                        context.tr(slide.titleKey),
                        style: AppTypography.h2,
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.gapH16,
                      Text(
                        context.tr(slide.descKey),
                        style: AppTypography.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
            
            // Indicator and Buttons
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    final isSelected = _currentIndex == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      width: isSelected ? 24.0 : 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryBlue : Colors.grey[400],
                        borderRadius: AppSpacing.radiusCircular,
                      ),
                    );
                  }),
                ),
                AppSpacing.gapH32,
                AppButton(
                  text: _currentIndex == _slides.length - 1
                      ? context.tr('onboarding_get_started')
                      : context.tr('continue'),
                  onPressed: () {
                    if (_currentIndex < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeOnboarding();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingModel {
  final String titleKey;
  final String descKey;
  final IconData icon;

  const OnboardingModel({
    required this.titleKey,
    required this.descKey,
    required this.icon,
  });
}
