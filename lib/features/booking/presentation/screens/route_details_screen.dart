import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/shared/widgets/cards.dart';
import '../../../../core/shared/widgets/loading.dart';
import '../../../../core/shared/widgets/empty_state.dart';
import '../../data/booking_repository.dart';
import '../../data/models/trip.dart';
import '../controllers/booking_controller.dart';

class RouteDetailsScreen extends ConsumerWidget {
  final String? departure;
  final String? arrival;

  const RouteDetailsScreen({
    super.key,
    this.departure,
    this.arrival,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsFuture = ref.watch(bookingRepositoryProvider).getTrips(
          departure: departure,
          arrival: arrival,
        );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(departure == null && arrival == null
            ? 'All Available Routes'
            : '${departure ?? "Any"} to ${arrival ?? "Any"}'),
      ),
      body: FutureBuilder<List<Trip>>(
        future: tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: AppLoading(size: 40.0));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading trips: ${snapshot.error}'),
            );
          }

          final trips = snapshot.data ?? [];
          if (trips.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Buses Scheduled',
              message: 'Currently there are no trips scheduled for this route. Please try another query.',
              icon: Icons.directions_bus_filled_outlined,
            );
          }

          return ListView.builder(
            padding: AppSpacing.pAll16,
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final isFull = trip.occupiedSeats.length >= 30;
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final departureDay = DateTime(trip.departureTime.year, trip.departureTime.month, trip.departureTime.day);
              final isExpired = departureDay.isBefore(today);
              final seatsTag = isFull
                  ? 'FULL'
                  : isExpired
                      ? 'EXPIRED'
                      : trip.availableSeats.toString();

              return Hero(
                tag: 'trip-card-${trip.id}',
                child: BusRouteCard(
                  departureCity: trip.departureCity,
                  arrivalCity: trip.arrivalCity,
                  departureTime: _formatTime(trip.departureTime),
                  arrivalTime: _formatTime(trip.arrivalTime),
                  price: '\$${trip.price.toStringAsFixed(2)}',
                  seatsLeft: seatsTag,
                  busNumber: trip.busNumber,
                  onTap: () {
                    if (isExpired) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Waqtiga wuu baxay (Departed). Lama sii ballansan karo!'),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                      return;
                    }
                    if (isFull) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Baska wuu buuxaa (30+ seats limit). Lama sii ballansan karo!'),
                          backgroundColor: AppColors.errorRed,
                        ),
                      );
                      return;
                    }
                    // Update controller with selected trip
                    ref.read(bookingFlowControllerProvider.notifier).selectTrip(trip);
                    context.push('/booking-seats');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final min = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }
}
