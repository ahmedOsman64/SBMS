import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/colors.dart';
import '../../config/spacing.dart';
import '../../config/typography.dart';
import '../localization/localization_provider.dart';

class AppBottomSheets {
  AppBottomSheets._();

  static Future<T?> showCustomBottomSheet<T>({
    required BuildContext context,
    required Widget builder,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.rXLarge),
            ),
          ),
          padding: EdgeInsets.only(
            top: AppSpacing.sm,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom sheet handle indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: AppSpacing.radiusCircular,
                ),
              ),
              builder,
            ],
          ),
        );
      },
    );
  }

  // Language Selector Bottom Sheet
  static void showLanguageSelector(BuildContext context) {
    showCustomBottomSheet<void>(
      context: context,
      builder: Consumer(
        builder: (context, ref, _) {
          final locale = ref.watch(localeProvider);
          final localeNotifier = ref.read(localeProvider.notifier);

          Widget languageTile(String title, String subtitle, String code) {
            final isSelected = locale.languageCode == code;
            return ListTile(
              title: Text(title, style: AppTypography.subtitle),
              subtitle: Text(subtitle, style: AppTypography.bodySmall),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                  : null,
              onTap: () {
                localeNotifier.setLocale(code);
                Navigator.pop(context);
              },
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('language'),
                style: AppTypography.h3,
              ),
              AppSpacing.gapH16,
              languageTile('English', 'Select English language', 'en'),
              const Divider(),
              languageTile('Soomaali', 'Dooro luqadda Soomaaliga', 'so'),
            ],
          );
        },
      ),
    );
  }
}
