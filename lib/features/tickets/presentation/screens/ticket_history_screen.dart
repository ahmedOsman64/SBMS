import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/widgets/empty_state.dart';
import '../../../../core/shared/widgets/passenger_nav_bar.dart';

class TicketHistoryScreen extends StatelessWidget {
  const TicketHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Read from local cache box to ensure offline access!
    final cacheBox = Hive.box(AppConstants.hiveCacheBox);
    final List<dynamic> tickets = cacheBox.get('offline_tickets', defaultValue: []);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('My Tickets'),
      ),
      body: tickets.isEmpty
          ? const EmptyStateWidget(
              title: 'No Tickets Found',
              message: 'You have not booked any bus trips yet. Active tickets will be saved here for offline use.',
              icon: Icons.confirmation_number_outlined,
            )
          : ListView.builder(
              padding: AppSpacing.pAll16,
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index] as Map;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: AppSpacing.pAll16,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      child: Icon(Icons.directions_bus_rounded),
                    ),
                    title: Text(
                      '${ticket['departure_city']} ➔ ${ticket['arrival_city']}',
                      style: AppTypography.subtitle,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSpacing.gapH4,
                        Text('Bus: ${ticket['bus_number']}'),
                        Text('Seats: ${(ticket['seats'] as List).join(", ")}'),
                      ],
                    ),
                    trailing: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryBlue, size: 36),
                    onTap: () {
                      context.push('/ticket-details?index=$index');
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: const PassengerNavBar(currentIndex: 2),
    );
  }
}
