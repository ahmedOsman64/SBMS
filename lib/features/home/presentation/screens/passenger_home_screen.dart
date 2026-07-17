import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/colors.dart';
import '../../../../core/config/spacing.dart';
import '../../../../core/config/typography.dart';
import '../../../../core/shared/localization/localization_provider.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/services/wallet_service.dart';
import '../../../../core/shared/widgets/cards.dart';
import '../../../../core/shared/widgets/passenger_nav_bar.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/data/models/trip.dart';
import '../../../booking/presentation/controllers/booking_controller.dart';

class PassengerHomeScreen extends ConsumerWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.tr('home')),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.pAll16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header banner card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppSpacing.radiusLarge,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('welcome'),
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            AppSpacing.gapH4,
                            Text(
                              user?.fullName ?? 'Somali Commuter',
                              style: AppTypography.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: AppSpacing.radiusCircular,
                          ),
                          child: Text(
                            user?.role.label ?? 'Passenger',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapH20,
                    const Divider(color: Colors.white24, height: 1),
                    AppSpacing.gapH16,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                            AppSpacing.gapW8,
                            Text(
                              'Wallet Balance',
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '\$${ref.watch(walletServiceProvider).toStringAsFixed(2)}',
                          style: AppTypography.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH24,
              
              // Bus Route Quick Search
              GestureDetector(
                onTap: () => context.push('/booking-search'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: AppSpacing.radiusMedium,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: 22),
                      AppSpacing.gapW12,
                      Expanded(
                        child: Text(
                          'Find a Bus Route (e.g. Mogadishu...)',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: AppSpacing.radiusSmall,
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.primaryBlue, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapH24,

              // Dashboard Statistics Metric Grid
              Text(
                'Overview',
                style: AppTypography.subtitle.copyWith(color: AppColors.primaryBlue),
              ),
              AppSpacing.gapH12,
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/booking-search'),
                    child: DashboardCard(
                      title: context.tr('bookings'),
                      value: 'Search Bus',
                      icon: Icons.bookmark_added_rounded,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/ticket-history'),
                    child: DashboardCard(
                      title: context.tr('tickets'),
                      value: 'My Passes',
                      icon: Icons.confirmation_number_rounded,
                      color: AppColors.secondaryTeal,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/wallet'),
                    child: DashboardCard(
                      title: context.tr('payments'),
                      value: 'My Wallet',
                      icon: Icons.payment_rounded,
                      color: AppColors.accentGold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/booking-search'),
                    child: DashboardCard(
                      title: context.tr('routes'),
                      value: 'All Routes',
                      icon: Icons.map_rounded,
                      color: AppColors.successGreen,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH24,

              // Active/Featured Booking Showcase
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Trips Today',
                    style: AppTypography.subtitle,
                  ),
                  TextButton(
                    onPressed: () => context.push('/booking-routes-details'),
                    child: const Text('See All'),
                  ),
                ],
              ),
              FutureBuilder<List<Trip>>(
                future: ref.watch(bookingRepositoryProvider).getTrips(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error loading trips: ${snapshot.error}'),
                    );
                  }

                  final trips = snapshot.data ?? [];
                  if (trips.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No trips available at the moment.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    );
                  }

                  // Show up to 3 featured trips
                  final featuredTrips = trips.take(3).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: featuredTrips.length,
                    itemBuilder: (context, index) {
                      final trip = featuredTrips[index];
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

                      return BusRouteCard(
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
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PassengerNavBar(currentIndex: 0),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final min = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }
}
