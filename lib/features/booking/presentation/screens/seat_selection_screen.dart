import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/widgets/buttons.dart';
import '../../../../core/shared/widgets/glass_container.dart';
import '../../data/booking_repository.dart';
import '../controllers/booking_controller.dart';

class SeatSelectionScreen extends ConsumerWidget {
  const SeatSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingFlowControllerProvider);
    final trip = state.selectedTrip;

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Seats')),
        body: const Center(child: Text('No trip selected. Please go back.')),
      );
    }

    // Subscribe to real-time seat updates!
    final occupiedSeatsStream = ref.watch(bookingRepositoryProvider).subscribeToSeatUpdates(trip.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('${trip.departureCity} - ${trip.arrivalCity}'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<String>>(
          stream: occupiedSeatsStream,
          initialData: trip.occupiedSeats,
          builder: (context, snapshot) {
            final occupiedList = snapshot.data ?? [];

            return Column(
              children: [
                // Top Legend Row
                Padding(
                  padding: AppSpacing.pAll16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _legendItem('Available', isDark ? AppColors.darkSurface : AppColors.white, border: true),
                      _legendItem('Selected', AppColors.primaryBlue),
                      _legendItem('Reserved', isDark ? AppColors.darkBorder : Colors.grey[350]!),
                    ],
                  ),
                ),
                
                // Front driver panel visualizer
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.grey[200],
                    borderRadius: AppSpacing.radiusMedium,
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.drive_eta_rounded, color: Colors.grey),
                        AppSpacing.gapW8,
                        Text('Front / Driver Cabin', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                
                // Seats Scrollable Grid Map
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Container(
                      padding: AppSpacing.pAll16,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.3) : Colors.grey[50],
                        borderRadius: AppSpacing.radiusLarge,
                      ),
                      child: Column(
                        children: List.generate(10, (rowIndex) {
                          // Generating 10 rows of A, B, C, D seats
                          final rowLetter = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'][rowIndex];
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                // Left Side: Seat 1 & 2
                                _seatButton(ref, '${rowLetter}1', occupiedList, state.selectedSeats, isDark),
                                AppSpacing.gapW8,
                                _seatButton(ref, '${rowLetter}2', occupiedList, state.selectedSeats, isDark),
                                
                                // Walkway gap spacer
                                const Expanded(child: SizedBox()),
                                
                                // Right Side: Seat 3 & 4
                                _seatButton(ref, '${rowLetter}3', occupiedList, state.selectedSeats, isDark),
                                AppSpacing.gapW8,
                                _seatButton(ref, '${rowLetter}4', occupiedList, state.selectedSeats, isDark),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                
                // Bottom Price Panel (Glassmorphism layout)
                GlassContainer(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.rXLarge)),
                  padding: AppSpacing.pAll24,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${state.selectedSeats.length} Seats Selected',
                              style: AppTypography.bodySmall,
                            ),
                            AppSpacing.gapH4,
                            Text(
                              '\$${(trip.price * state.selectedSeats.length).toStringAsFixed(2)}',
                              style: AppTypography.h2.copyWith(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: AppButton(
                          text: 'Choose Payment',
                          onPressed: state.selectedSeats.isNotEmpty
                              ? () => context.push('/booking-payment')
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _legendItem(String text, Color color, {bool border = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.0),
            border: border ? Border.all(color: Colors.grey) : null,
          ),
        ),
        AppSpacing.gapW8,
        Text(text, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _seatButton(
    WidgetRef ref,
    String code,
    List<String> occupied,
    List<String> selected,
    bool isDark,
  ) {
    final isOccupied = occupied.contains(code);
    final isSelected = selected.contains(code);

    Color getBgColor() {
      if (isOccupied) return isDark ? AppColors.darkBorder : Colors.grey[350]!;
      if (isSelected) return AppColors.primaryBlue;
      return isDark ? AppColors.darkSurface : AppColors.white;
    }

    Color getFgColor() {
      if (isOccupied) return Colors.grey;
      if (isSelected) return AppColors.white;
      return isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    }

    return Material(
      color: getBgColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: isSelected 
              ? AppColors.primaryBlue 
              : (isOccupied ? Colors.transparent : Colors.grey.withValues(alpha: 0.4)),
        ),
      ),
      child: InkWell(
        onTap: isOccupied
            ? null
            : () => ref.read(bookingFlowControllerProvider.notifier).toggleSeat(code),
        borderRadius: BorderRadius.circular(8.0),
        child: SizedBox(
          width: 50.0,
          height: 50.0,
          child: Center(
            child: Text(
              code,
              style: AppTypography.label.copyWith(
                color: getFgColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
