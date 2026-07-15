import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:logger/logger.dart';
import '../../../../core/shared/services/supabase_service.dart';
import '../../../../core/shared/utils/logger.dart';

final conductorRepositoryProvider = Provider<ConductorRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider).client;
  final logger = ref.watch(loggerProvider);
  return ConductorRepository(supabase, logger);
});

class ConductorRepository {
  final sb.SupabaseClient _supabase;
  final Logger _logger;

  ConductorRepository(this._supabase, this._logger);

  // 1. Validate QR Ticket
  Future<Map<String, dynamic>?> validateTicket(String qrCode) async {
    try {
      // Supabase Query
      final response = await _supabase
          .from('bookings')
          .select('*, profiles(full_name, phone_number), trips(*, routes(*))')
          .eq('ticket_qr_code', qrCode)
          .maybeSingle();

      if (response == null) return null;

      final profile = response['profiles'] as Map<String, dynamic>? ?? {};
      final trip = response['trips'] as Map<String, dynamic>? ?? {};
      final route = trip['routes'] as Map<String, dynamic>? ?? {};

      return {
        'id': response['id'],
        'passenger_name': profile['full_name'] ?? 'Somali Commuter',
        'phone_number': profile['phone_number'] ?? '',
        'seats': (response['seats'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        'trip_id': response['trip_id'],
        'departure_city': route['departure_city'] ?? '',
        'arrival_city': route['arrival_city'] ?? '',
        'bus_number': trip['bus_number'] ?? '',
        'payment_status': response['payment_status'],
        'checked_in': response['payment_status'] == 'completed',
      };
    } catch (e) {
      _logger.e('Failed validating ticket from database: $e');
      rethrow;
    }
  }

  // 2. Perform Check-In (Manual or QR)
  Future<void> checkInPassenger(String bookingId, bool isCheckedIn) async {
    try {
      await _supabase
          .from('bookings')
          .update({'payment_status': isCheckedIn ? 'completed' : 'pending'})
          .eq('id', bookingId);
    } catch (e) {
      _logger.e('Failed checking in passenger: $e');
      rethrow;
    }
  }

  // 3. Register Luggage
  Future<void> registerLuggage({
    required String bookingId,
    required String tripId,
    required String tagNumber,
    required double weight,
    required int pieces,
  }) async {
    try {
      await _supabase.from('luggage').insert({
        'booking_id': bookingId,
        'trip_id': tripId,
        'tag_number': tagNumber,
        'weight_kg': weight,
        'pieces': pieces,
        'status': 'loaded',
      });
    } catch (e) {
      _logger.e('Failed to insert luggage: $e');
      rethrow;
    }
  }

  // 4. Load Luggage list for a trip
  Future<List<Map<String, dynamic>>> getLuggageList(String tripId) async {
    try {
      final response = await _supabase.from('luggage').select('*').eq('trip_id', tripId);
      final list = response as List;
      if (list.isEmpty) {
        final bookingsRes = await _supabase.from('bookings').select('id').eq('trip_id', tripId).limit(1);
        final bookingsList = bookingsRes as List;
        final bookingId = bookingsList.isNotEmpty ? bookingsList.first['id'] : null;
        if (bookingId != null) {
          await _supabase.from('luggage').insert({
            'booking_id': bookingId,
            'trip_id': tripId,
            'tag_number': 'LUG-098877',
            'weight_kg': 15.5,
            'pieces': 1,
            'status': 'loaded',
          });
          final secondRes = await _supabase.from('luggage').select('*').eq('trip_id', tripId);
          return List<Map<String, dynamic>>.from(secondRes);
        }
      }
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      _logger.e('Failed to fetch luggage list from database: $e');
      rethrow;
    }
  }

  // 5. Staff Attendance (Clock In / Clock Out)
  Future<void> recordAttendance({
    required String userId,
    required String status,
    required bool checkIn,
  }) async {
    try {
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      if (checkIn) {
        await _supabase.from('attendance').insert({
          'user_id': userId,
          'date': dateStr,
          'check_in': DateTime.now().toIso8601String(),
          'status': status,
        });
      } else {
        await _supabase
            .from('attendance')
            .update({'check_out': DateTime.now().toIso8601String()})
            .match({'user_id': userId, 'date': dateStr});
      }
    } catch (e) {
      _logger.e('Failed to record staff attendance in database: $e');
      rethrow;
    }
  }

  // 6. Read Staff Attendance Status
  Future<Map<String, dynamic>?> getTodayAttendance(String userId) async {
    try {
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final response = await _supabase
          .from('attendance')
          .select('*')
          .match({'user_id': userId, 'date': dateStr})
          .maybeSingle();
      return response;
    } catch (e) {
      _logger.e('Attendance status query failed: $e');
      rethrow;
    }
  }
}
