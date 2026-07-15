import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:logger/logger.dart';
import 'dart:math';

import '../../../../core/shared/services/supabase_service.dart';
import '../../../../core/shared/utils/logger.dart';
import '../../../../core/shared/exceptions/failures.dart';
import 'models/trip.dart';
import 'models/booking.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider).client;
  final logger = ref.watch(loggerProvider);
  return BookingRepository(supabase, logger);
});

class BookingRepository {
  final sb.SupabaseClient _supabase;
  final Logger _logger;

  BookingRepository(this._supabase, this._logger);

  // 1. Get Scheduled Trips
  Future<List<Trip>> getTrips({String? departure, String? arrival}) async {
    try {
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
      _logger.e('Failed querying Supabase trips: $e');
      rethrow;
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
        'available_seats': 40 - newOccupied.length,
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
      final response = await _supabase.from('bookings').select().eq('user_id', userId);
      return (response as List).map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Failed to fetch booking history: $e');
      rethrow;
    }
  }

  // 4. Real-time Seat Changes
  Stream<List<String>> subscribeToSeatUpdates(String tripId) {
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
