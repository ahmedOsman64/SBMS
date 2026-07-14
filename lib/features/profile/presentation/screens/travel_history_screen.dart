import 'package:flutter/material.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/widgets/cards.dart';

class TravelHistoryScreen extends StatelessWidget {
  const TravelHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Travel History')),
      body: SingleChildScrollView(
        padding: AppSpacing.pAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Travel Statistics Summary Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: const [
                DashboardCard(
                  title: 'Total Trips',
                  value: '14 journeys',
                  icon: Icons.map_rounded,
                  color: AppColors.primaryBlue,
                ),
                DashboardCard(
                  title: 'Total Fares',
                  value: '\$185.00',
                  icon: Icons.monetization_on_rounded,
                  color: AppColors.successGreen,
                ),
              ],
            ),
            AppSpacing.gapH24,
            
            const Text('Recent Journeys Log', style: AppTypography.subtitle),
            AppSpacing.gapH12,

            // Travel logs list cards
            _travelLogCard(
              departure: 'Mogadishu',
              arrival: 'Garowe',
              date: 'July 10, 2026',
              price: '\$25.00',
              status: 'Completed',
              statusColor: AppColors.successGreen,
            ),
            _travelLogCard(
              departure: 'Hargeisa',
              arrival: 'Burao',
              date: 'June 28, 2026',
              price: '\$12.00',
              status: 'Completed',
              statusColor: AppColors.successGreen,
            ),
            _travelLogCard(
              departure: 'Mogadishu',
              arrival: 'Kismayo',
              date: 'May 14, 2026',
              price: '\$18.00',
              status: 'Canceled',
              statusColor: AppColors.errorRed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _travelLogCard({
    required String departure,
    required String arrival,
    required String date,
    required String price,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: AppSpacing.pAll16,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$departure ➔ $arrival', style: AppTypography.subtitle),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: AppSpacing.radiusCircular,
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            AppSpacing.gapH8,
            const Divider(),
            AppSpacing.gapH8,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date: $date', style: AppTypography.bodySmall),
                Text('Fare: $price', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
