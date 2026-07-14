import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/spacing.dart';
import '../../config/typography.dart';

enum ButtonType { primary, secondary, outlined, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color getBgColor() {
      if (onPressed == null) return isDark ? AppColors.darkBorder : AppColors.lightBorder;
      switch (type) {
        case ButtonType.primary:
          return AppColors.primaryBlue;
        case ButtonType.secondary:
          return AppColors.accentGold;
        case ButtonType.outlined:
        case ButtonType.text:
          return Colors.transparent;
      }
    }

    Color getFgColor() {
      if (onPressed == null) return isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
      switch (type) {
        case ButtonType.primary:
          return AppColors.white;
        case ButtonType.secondary:
          return AppColors.lightTextPrimary;
        case ButtonType.outlined:
          return AppColors.primaryBlue;
        case ButtonType.text:
          return isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
      }
    }

    BorderSide? getBorder() {
      if (type == ButtonType.outlined) {
        return BorderSide(
          color: onPressed == null
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : AppColors.primaryBlue,
          width: 1.5,
        );
      }
      return null;
    }

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 20.0, color: getFgColor()),
          AppSpacing.gapW8,
        ],
        if (isLoading)
          SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(getFgColor()),
            ),
          )
        else
          Text(
            text,
            style: AppTypography.button.copyWith(color: getFgColor()),
          ),
      ],
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: getBgColor(),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusMedium,
          side: getBorder() ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          overlayColor: WidgetStateProperty.all(
            getFgColor().withValues(alpha: 0.1),
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}

// Custom selector for Somali Mobile Payment Options (e.g. EVC Plus, Zaad, Sahal)
class MobileMoneyButton extends StatelessWidget {
  final String providerName; // e.g. EVC Plus, Zaad, Sahal
  final String subtitle;     // e.g. Hormuud, Telesom, Golis
  final bool isSelected;
  final VoidCallback onTap;

  const MobileMoneyButton({
    super.key,
    required this.providerName,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isSelected 
        ? AppColors.primaryBlue.withValues(alpha: 0.08)
        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.radiusMedium,
        side: BorderSide(
          color: isSelected 
            ? AppColors.primaryBlue 
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.radiusMedium,
        child: Padding(
          padding: AppSpacing.pAll16,
          child: Row(
            children: [
              // Beautiful indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.circle, size: 10, color: AppColors.primaryBlue),
                      )
                    : null,
              ),
              AppSpacing.gapW16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      style: AppTypography.subtitle.copyWith(
                        color: isSelected 
                          ? AppColors.primaryBlue 
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.phone_android, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
