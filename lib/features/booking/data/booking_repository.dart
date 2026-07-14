import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:logger/logger.dart';
import 'dart:math';

import '../../../../core/shared/services/supabase_service.dart';
import '../../../../core/shared/utils/logger.dart';
import '../../../../core/shared/exceptions/failures.dart';
import 'models/trip.dart';
import 'models/booking.dart';
import '../../../../core/config/constants.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider).client;
  final logger = ref.watch(loggerProvider);
  return BookingRepository(supabase, logger);
});

class BookingRepository {
  final sb.SupabaseClient _supabase;
  final Logger _logger;

  BookingRepository(this._supabase, this._logger);

  // Generate Mock fallback data if Supabase keys are placeholder
  final List<Trip> _mockTrips = [
    Trip(
      id: 'trip-1',
      routeId: 'route-mog-grw',
      departureCity: 'Mogadishu',
      arrivalCity: 'Garowe',
      departureTime: DateTime.now().add(const Duration(hours: 4)),
      arrivalTime: DateTime.now().add(const Duration(hours: 12)),
      busNumber: 'MOG-GRW-08',
      totalSeats: 40,
      availableSeats: 36,
      occupiedSeats: const ['A1', 'A2', 'B3', 'B4'],
      price: 25.0,
    ),
    Trip(
      id: 'trip-2',
      routeId: 'route-har-bur',
      departureCity: 'Hargeisa',
      arrivalCity: 'Burao',
      departureTime: DateTime.now().add(const Duration(hours: 6)),
      arrivalTime: DateTime.now().add(const Duration(hours: 10)),
      busNumber: 'HAR-BUR-02',
      totalSeats: 40,
      availableSeats: 31,
      occupiedSeats: const ['A1', 'A2', 'A3', 'A4', 'B1', 'B2', 'C1', 'C2', 'D1'],
      price: 12.0,
    ),
    Trip(
      id: 'trip-3',
      routeId: 'route-mog-kis',
      departureCity: 'Mogadishu',
      arrivalCity: 'Kismayo',
      departureTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      arrivalTime: DateTime.now().add(const Duration(days: 1, hours: 8)),
      busNumber: 'MOG-KIS-05',
      totalSeats: 40,
      availableSeats: 39,
      occupiedSeats: const ['A1'],
      price: 18.0,
    ),
  ];

  final List<Booking> _localBookingsCache = [];

  // 1. Get Scheduled Trips
  Future<List<Trip>> getTrips({String? departure, String? arrival}) async {
    try {
      // Return local mockup if server is unreachable or settings are mock
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 600));
        return _mockTrips.where((trip) {
          final matchDep = departure == null || trip.departureCity.toLowerCase().contains(departure.toLowerCase());
          final matchArr = arrival == null || trip.arrivalCity.toLowerCase().contains(arrival.toLowerCase());
          return matchDep && matchArr;
        }).toList();
      }

      // Supabase Query
      var query = _supabase.from('trips').select('*, routes(*)');
      if (departure != null) {
        query = query.eq('routes.departure_city', departure);
      }
      if (arrival != null) {
        query = query.eq('routes.arrival_city', arrival);
      }
      
      final response = await query;
      return (response as List).map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      _logger.w('Failed querying Supabase, falling back to mock database: $e');
      return _mockTrips;
    }
  }

  // 2. Create Booking and Prevent Duplicates
  Future<Booking> createBooking({
    required String userId,
    required String tripId,
    required List<String> seats,
    required double totalPrice,
    required String paymentMethod,
  }) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(seconds: 1));
        
        // Find local trip to ensure no seat double bookings
        final tripIndex = _mockTrips.indexWhere((t) => t.id == tripId);
        if (tripIndex != -1) {
          final trip = _mockTrips[tripIndex];
          final doubleBooked = seats.any((seat) => trip.occupiedSeats.contains(seat));
          if (doubleBooked) {
            throw const ValidationFailure('One or more selected seats are already reserved. Please select another seat.');
          }
          
          // Reserve the seats locally
          final updatedOccupied = List<String>.from(trip.occupiedSeats)..addAll(seats);
          _mockTrips[tripIndex] = trip.copyWith(
            occupiedSeats: updatedOccupied,
            availableSeats: trip.totalSeats - updatedOccupied.length,
          );
        }

        final mockBooking = Booking(
          id: 'booking-${Random().nextInt(99999)}',
          userId: userId,
          tripId: tripId,
          seats: seats,
          totalPrice: totalPrice,
          paymentMethod: paymentMethod,
          paymentStatus: 'completed',
          ticketQrCode: 'SBMS-TICKET-${Random().nextInt(999999)}-$tripId-${seats.join("-")}',
          createdAt: DateTime.now(),
        );

        _localBookingsCache.add(mockBooking);
        return mockBooking;
      }

      // Supabase live check to avoid duplicates inside database transaction blocks
      final tripResponse = await _supabase.from('trips').select('occupied_seats').eq('id', tripId).single();
      final List<String> occupied = List<String>.from(tripResponse['occupied_seats'] ?? []);
      
      if (seats.any((seat) => occupied.contains(seat))) {
        throw const ValidationFailure('Double booking prevention: Selected seat(s) have just been reserved.');
      }

      final ticketQr = 'SBMS-TICKET-${Random().nextInt(999999)}-$tripId';

      final bookingJson = {
        'user_id': userId,
        'trip_id': tripId,
        'seats': seats,
        'total_price': totalPrice,
        'payment_method': paymentMethod,
        'payment_status': 'completed',
        'ticket_qr_code': ticketQr,
      };

      // 1. Insert Booking record
      final bookingResponse = await _supabase.from('bookings').insert(bookingJson).select().single();
      
      // 2. Update occupied seats in Scheduled Trip
      final newOccupied = List<String>.from(occupied)..addAll(seats);
      await _supabase.from('trips').update({
        'occupied_seats': newOccupied,
        'available_seats': 40 - newOccupied.length, // Mock config subtract
      }).eq('id', tripId);

      return Booking.fromJson(bookingResponse);
    } catch (e) {
      if (e is Failure) rethrow;
      throw FailureHandler.handleException(e, _logger);
    }
  }

  // 3. Get Booking History
  Future<List<Booking>> getBookingHistory(String userId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 500));
        return _localBookingsCache;
      }

      final response = await _supabase.from('bookings').select().eq('user_id', userId);
      return (response as List).map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      return _localBookingsCache;
    }
  }

  // 4. Real-time Seat Changes Simulation
  Stream<List<String>> subscribeToSeatUpdates(String tripId) {
    if (AppConstants.supabaseUrl.contains('your-project-id')) {
      // Mock periodic random seat occupancy to show off REALTIME UI updates!
      return Stream.periodic(const Duration(seconds: 8), (count) {
        final trip = _mockTrips.firstWhere((t) => t.id == tripId, orElse: () => _mockTrips.first);
        
        // Randomly occupy a new seat like A4, B5, etc.
        if (count < 5 && trip.availableSeats > 5) {
          final randomSeatLetters = ['A', 'B', 'C', 'D', 'E'];
          final randLetter = randomSeatLetters[Random().nextInt(randomSeatLetters.length)];
          final randNum = Random().nextInt(8) + 1;
          final newOccupiedSeat = '$randLetter$randNum';
          
          if (!trip.occupiedSeats.contains(newOccupiedSeat)) {
            final list = List<String>.from(trip.occupiedSeats)..add(newOccupiedSeat);
            // update in place
            final idx = _mockTrips.indexWhere((t) => t.id == tripId);
            if (idx != -1) {
              _mockTrips[idx] = trip.copyWith(
                occupiedSeats: list,
                availableSeats: trip.totalSeats - list.length,
              );
            }
          }
        }
        return _mockTrips.firstWhere((t) => t.id == tripId).occupiedSeats;
      });
    }

    // Live Supabase Realtime Subscription Channel
    return _supabase
        .from('trips')
        .stream(primaryKey: ['id'])
        .eq('id', tripId)
        .map((maps) {
          if (maps.isEmpty) return [];
          final occupied = maps.first['occupied_seats'] as List?;
          return occupied?.map((e) => e.toString()).toList() ?? [];
        });
  }
}
