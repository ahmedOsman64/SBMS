import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/theme_notifier.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/localization/localization_provider.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/widgets/bottom_sheets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final isDarkScaffold = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkScaffold ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      body: ListView(
        padding: AppSpacing.pAll16,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            key: const ValueKey('pref_section_title'),
            child: Text(
              'Preferences',
              style: AppTypography.label.copyWith(color: AppColors.primaryBlue),
            ),
          ),
          Card(
            child: Column(
              children: [
                // Language Tile
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.primaryBlue),
                  title: Text(context.tr('language'), style: AppTypography.subtitle),
                  subtitle: Text(
                    locale.languageCode == 'en' ? 'English' : 'Soomaali',
                    style: AppTypography.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => AppBottomSheets.showLanguageSelector(context),
                ),
                const Divider(height: 1),
                // Dark Mode Switch Tile
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_rounded, color: AppColors.primaryBlue),
                  title: Text(context.tr('dark_mode'), style: AppTypography.subtitle),
                  subtitle: Text(
                    isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                    style: AppTypography.bodySmall,
                  ),
                  value: isDarkMode,
                  onChanged: (bool value) {
                    ref.read(themeModeProvider.notifier).toggleTheme(value);
                  },
                ),
              ],
            ),
          ),
          AppSpacing.gapH24,
          
          // Auth Action Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
              title: Text(
                context.tr('logout'),
                style: AppTypography.subtitle.copyWith(color: AppColors.errorRed),
              ),
              onTap: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
