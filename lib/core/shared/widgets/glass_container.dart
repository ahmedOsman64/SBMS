import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/spacing.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? shadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius,
    this.blurSigma = 12.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding,
    this.margin,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Responsive premium opacity values for glassmorphism
    final defaultBgColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.5)
        : AppColors.white.withValues(alpha: 0.6);

    final defaultBorderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.3)
        : AppColors.lightBorder.withValues(alpha: 0.4);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: shadow ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? AppSpacing.radiusMedium,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding ?? AppSpacing.pAll16,
            decoration: BoxDecoration(
              color: backgroundColor ?? defaultBgColor,
              borderRadius: borderRadius ?? AppSpacing.radiusMedium,
              border: Border.all(
                color: borderColor ?? defaultBorderColor,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
