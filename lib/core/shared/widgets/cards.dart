import 'package:flutter/material.dart';
import '../../config/colors.dart';
import '../../config/spacing.dart';
import '../../config/typography.dart';

// Dashboard Metrics Card
class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = color ?? AppColors.primaryBlue;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.radiusMedium,
        border: Border.all(
          color: cardColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: isDark ? 0.05 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.radiusMedium,
        child: Stack(
          children: [
            // Ambient glow in the corner
            Positioned(
              right: -10,
              top: -10,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: AppSpacing.pAll12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cardColor, cardColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20.0),
                  ),
                  AppSpacing.gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppSpacing.gapH4,
                        Text(
                          value,
                          style: AppTypography.subtitle.copyWith(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bus booking detail card representation (Redesigned as a travel ticket)
class BusRouteCard extends StatelessWidget {
  final String departureCity;
  final String arrivalCity;
  final String departureTime;
  final String arrivalTime;
  final String price;
  final String seatsLeft;
  final String busNumber;
  final VoidCallback onTap;

  const BusRouteCard({
    super.key,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.seatsLeft,
    required this.busNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppSpacing.radiusMedium,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.radiusMedium,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: AppSpacing.pAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upper ticket section (Route details)
                  Row(
                    children: [
                      // Departure city
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              departureTime,
                              style: AppTypography.subtitle.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.gapH4,
                            Text(
                              departureCity,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Route dashed visual line
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1.5,
                                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus_rounded,
                                    color: AppColors.primaryBlue,
                                    size: 14,
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1.5,
                                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                  ),
                                ),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            AppSpacing.gapH4,
                            Text(
                              'Direct',
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrival city
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              arrivalTime,
                              style: AppTypography.subtitle.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AppSpacing.gapH4,
                            Text(
                              arrivalCity,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH16,
                  // Dashed divider simulating a tear-off ticket coupon
                  Row(
                    children: List.generate(
                      150 ~/ 3,
                      (index) => Expanded(
                        child: Container(
                          color: index % 2 == 0 ? Colors.transparent : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapH16,
                  // Lower ticket section (Bus details, price, seats)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                              borderRadius: AppSpacing.radiusSmall,
                            ),
                            child: Text(
                              busNumber,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                          AppSpacing.gapW12,
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: (seatsLeft.toUpperCase().contains('FULL') ||
                                      seatsLeft == '0' ||
                                      seatsLeft.toUpperCase().contains('EXPIRED') ||
                                      seatsLeft.toUpperCase().contains('DEPARTED'))
                                  ? AppColors.errorRed.withValues(alpha: 0.15)
                                  : AppColors.errorRed.withValues(alpha: 0.08),
                              borderRadius: AppSpacing.radiusSmall,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_seat_rounded, size: 12, color: AppColors.errorRed),
                                AppSpacing.gapW4,
                                Text(
                                  (seatsLeft.toUpperCase().contains('FULL') || seatsLeft == '0')
                                      ? 'FULL (Buuxa)'
                                      : (seatsLeft.toUpperCase().contains('EXPIRED') ||
                                              seatsLeft.toUpperCase().contains('DEPARTED'))
                                          ? 'EXPIRED (Baxay)'
                                          : '$seatsLeft seats left',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.errorRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        price,
                        style: AppTypography.h3.copyWith(
                          color: AppColors.secondaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
