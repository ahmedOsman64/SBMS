import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/widgets/buttons.dart';
import '../../../../core/shared/widgets/glass_container.dart';
import '../controllers/booking_controller.dart';

class BookingConfirmScreen extends ConsumerStatefulWidget {
  const BookingConfirmScreen({super.key});

  @override
  ConsumerState<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends ConsumerState<BookingConfirmScreen> {
  @override
  void initState() {
    super.initState();
    _cacheTicketLocally();
  }

  void _cacheTicketLocally() {
    final state = ref.read(bookingFlowControllerProvider);
    final booking = state.completedBooking;
    final trip = state.selectedTrip;

    if (booking != null && trip != null) {
      try {
        final cacheBox = Hive.box(AppConstants.hiveCacheBox);
        // Cache this booking details as map for offline checks
        final ticketData = {
          'booking_id': booking.id,
          'departure_city': trip.departureCity,
          'arrival_city': trip.arrivalCity,
          'departure_time': trip.departureTime.toIso8601String(),
          'bus_number': trip.busNumber,
          'seats': booking.seats,
          'qr_code': booking.ticketQrCode,
          'total_price': booking.totalPrice,
        };
        
        // Save in a dynamic list of active tickets
        final List<dynamic> currentTickets = cacheBox.get('offline_tickets', defaultValue: []);
        currentTickets.add(ticketData);
        cacheBox.put('offline_tickets', currentTickets);
      } catch (_) {
        // Cache writing failure, continue flow
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingFlowControllerProvider);
    final booking = state.completedBooking;
    final trip = state.selectedTrip;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (booking == null || trip == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Session expired or booking not found.'),
              AppSpacing.gapH16,
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pAll24,
          child: Column(
            children: [
              AppSpacing.gapH24,
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.successGreen,
                size: 72.0,
              ),
              AppSpacing.gapH16,
              const Text('Booking Confirmed!', style: AppTypography.h2),
              AppSpacing.gapH8,
              const Text(
                'Your ticket is saved. You can access it offline anytime.',
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH32,

              // Glassmorphic ticket card container layout
              GlassContainer(
                child: Column(
                  children: [
                    // Cities Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(trip.departureCity, style: AppTypography.subtitle),
                            const Text('Departure', style: AppTypography.bodySmall),
                          ],
                        ),
                        const Icon(Icons.arrow_right_alt_rounded, color: AppColors.primaryBlue, size: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(trip.arrivalCity, style: AppTypography.subtitle),
                            const Text('Arrival', style: AppTypography.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    
                    // Bus Number and Seats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bus Number', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(trip.busNumber, style: AppTypography.bodyMedium),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Seats Reserved', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(booking.seats.join(', '), style: AppTypography.bodyMedium),
                          ],
                        ),
                      ],
                    ),
                    AppSpacing.gapH24,
                    
                    // QR Code Visualizer
                    Container(
                      padding: AppSpacing.pAll12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.radiusMedium,
                      ),
                      child: Column(
                        children: [
                          // Custom Painter or clean box rendering representing QR Code
                          CustomPaint(
                            size: const Size(160, 160),
                            painter: TicketQRPainter(code: booking.ticketQrCode),
                          ),
                          AppSpacing.gapH8,
                          Text(
                            booking.ticketQrCode,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH48,
              AppButton(
                text: 'Done',
                onPressed: () {
                  ref.read(bookingFlowControllerProvider.notifier).reset();
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter to render a realistic Mock QR code grid
class TicketQRPainter extends CustomPainter {
  final String code;

  TicketQRPainter({required this.code});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Drawing mock finder patterns on corners (top-left, top-right, bottom-left)
    double boxSize = 35.0;
    
    // Top-Left Finder
    canvas.drawRect(Rect.fromLTWH(0, 0, boxSize, boxSize), paint);
    canvas.drawRect(Rect.fromLTWH(6, 6, boxSize - 12, boxSize - 12), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(10, 10, boxSize - 20, boxSize - 20), paint);

    // Top-Right Finder
    canvas.drawRect(Rect.fromLTWH(size.width - boxSize, 0, boxSize, boxSize), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - boxSize + 6, 6, boxSize - 12, boxSize - 12), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(size.width - boxSize + 10, 10, boxSize - 20, boxSize - 20), paint);

    // Bottom-Left Finder
    canvas.drawRect(Rect.fromLTWH(0, size.height - boxSize, boxSize, boxSize), paint);
    canvas.drawRect(Rect.fromLTWH(6, size.height - boxSize + 6, boxSize - 12, boxSize - 12), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(10, size.height - boxSize + 10, boxSize - 20, boxSize - 20), paint);

    // Draw some random mock data blocks in the middle of QR code
    final rand = code.hashCode;
    for (int x = 2; x < 15; x++) {
      for (int y = 2; y < 15; y++) {
        // Skip finder pattern zones
        if (x < 6 && y < 6) continue;
        if (x > 10 && y < 6) continue;
        if (x < 6 && y > 10) continue;

        // Deterministic mock pixel grids
        if ((rand ^ (x * y + x)) % 3 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * (size.width / 16),
              y * (size.height / 16),
              size.width / 16 - 1,
              size.height / 16 - 1,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
