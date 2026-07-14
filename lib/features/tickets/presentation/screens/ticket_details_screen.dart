import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/widgets/glass_container.dart';
import '../../../booking/presentation/screens/booking_confirm_screen.dart';

class TicketDetailsScreen extends StatelessWidget {
  final int index;

  const TicketDetailsScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Retrieve ticket locally from Hive
    final cacheBox = Hive.box(AppConstants.hiveCacheBox);
    final List<dynamic> tickets = cacheBox.get('offline_tickets', defaultValue: []);
    
    if (index >= tickets.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ticket Details')),
        body: const Center(child: Text('Ticket not found.')),
      );
    }

    final ticket = tickets[index] as Map;
    final seats = (ticket['seats'] as List).cast<String>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Ticket Pass'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pAll24,
        child: Column(
          children: [
            // Glassmorphic Ticket layout representation
            GlassContainer(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ticket['departure_city'].toString(), style: AppTypography.subtitle),
                          const Text('From', style: AppTypography.bodySmall),
                        ],
                      ),
                      const Icon(Icons.arrow_right_alt_rounded, color: AppColors.primaryBlue, size: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(ticket['arrival_city'].toString(), style: AppTypography.subtitle),
                          const Text('To', style: AppTypography.bodySmall),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bus Scheduled', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(ticket['bus_number'].toString()),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Departure Date', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(ticket['departure_time'].toString().substring(0, 10)),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.gapH24,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Seats', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(seats.join(', ')),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Fare Paid', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('\$${(ticket['total_price'] as double).toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.gapH32,
                  
                  // QR code render box
                  Container(
                    padding: AppSpacing.pAll12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.radiusMedium,
                    ),
                    child: Column(
                      children: [
                        CustomPaint(
                          size: const Size(180, 180),
                          painter: TicketQRPainter(code: ticket['qr_code'].toString()),
                        ),
                        AppSpacing.gapH8,
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off_rounded, color: Colors.grey, size: 14),
                            AppSpacing.gapW4,
                            Text(
                              'Offline Verified Pass',
                              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
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
