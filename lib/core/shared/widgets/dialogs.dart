import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/spacing.dart';
import '../../config/typography.dart';
import 'buttons.dart';

class AppDialogs {
  AppDialogs._();

  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          elevation: 10,
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radiusLarge,
          ),
          child: Padding(
            padding: AppSpacing.pAll24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Container(
                    padding: AppSpacing.pAll16,
                    decoration: BoxDecoration(
                      color: (iconColor ?? AppColors.primaryBlue).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: iconColor ?? AppColors.primaryBlue,
                      size: 40.0,
                    ),
                  ),
                  AppSpacing.gapH24,
                ],
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH12,
                Text(
                  message,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH24,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (cancelLabel != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: AppButton(
                            text: cancelLabel,
                            type: ButtonType.outlined,
                            onPressed: () {
                              Navigator.pop(context);
                              if (onCancel != null) onCancel();
                            },
                          ),
                        ),
                      ),
                    if (confirmLabel != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: AppButton(
                            text: confirmLabel,
                            onPressed: () {
                              Navigator.pop(context);
                              if (onConfirm != null) onConfirm();
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonLabel,
    VoidCallback? onPressed,
  }) {
    return showCustomDialog<void>(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.successGreen,
      confirmLabel: buttonLabel ?? 'Done',
      onConfirm: onPressed,
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonLabel,
    VoidCallback? onPressed,
  }) {
    return showCustomDialog<void>(
      context: context,
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.errorRed,
      confirmLabel: buttonLabel ?? 'Dismiss',
      onConfirm: onPressed,
    );
  }
}
