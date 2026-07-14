import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:logger/logger.dart';
import '../../../../core/shared/services/supabase_service.dart';
import '../../../../core/shared/utils/logger.dart';
import '../../../../core/config/constants.dart';

final conductorRepositoryProvider = Provider<ConductorRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider).client;
  final logger = ref.watch(loggerProvider);
  return ConductorRepository(supabase, logger);
});

class ConductorRepository {
  final sb.SupabaseClient _supabase;
  final Logger _logger;

  ConductorRepository(this._supabase, this._logger);

  // In-memory cache mock data for luggage and attendance
  final List<Map<String, dynamic>> _mockLuggage = [];
  final List<Map<String, dynamic>> _mockAttendance = [];

  // Mocked active bookings database
  final Map<String, Map<String, dynamic>> _mockBookings = {
    'TICKET-111': {
      'id': 'booking-uuid-1',
      'passenger_name': 'Ahmed Ali Moallim',
      'phone_number': '+252 61 5551234',
      'seats': ['A1', 'A2'],
      'trip_id': 'd9b8a7c6-2222-3333-4444-555566667777',
      'departure_city': 'Mogadishu',
      'arrival_city': 'Garowe',
      'bus_number': 'MOG-GRW-08',
      'payment_status': 'completed',
      'checked_in': false,
    },
    'TICKET-222': {
      'id': 'booking-uuid-2',
      'passenger_name': 'Halima Warsame',
      'phone_number': '+252 61 8882233',
      'seats': ['B3'],
      'trip_id': 'd9b8a7c6-2222-3333-4444-555566667777',
      'departure_city': 'Mogadishu',
      'arrival_city': 'Garowe',
      'bus_number': 'MOG-GRW-08',
      'payment_status': 'completed',
      'checked_in': true,
    },
    'TICKET-333': {
      'id': 'booking-uuid-3',
      'passenger_name': 'Farah Osman',
      'phone_number': '+252 61 9993344',
      'seats': ['C1', 'C2'],
      'trip_id': 'c8b7a6d5-4444-5555-6666-777788889999',
      'departure_city': 'Hargeisa',
      'arrival_city': 'Burao',
      'bus_number': 'HAR-BUR-02',
      'payment_status': 'completed',
      'checked_in': false,
    }
  };

  // 1. Validate QR Ticket
  Future<Map<String, dynamic>?> validateTicket(String qrCode) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 400));
        // Check contains/starts with matching keys
        final matchKey = _mockBookings.keys.firstWhere(
          (k) => qrCode.toUpperCase().contains(k), 
          orElse: () => '',
        );
        if (matchKey.isNotEmpty) {
          return _mockBookings[matchKey];
        }
        // If not found, return random ticket details for demo/testing!
        return {
          'id': 'booking-uuid-gen',
          'passenger_name': 'Somali Commuter (Demo Scanned)',
          'phone_number': '+252 61 7771234',
          'seats': ['B1'],
          'trip_id': 'd9b8a7c6-2222-3333-4444-555566667777',
          'departure_city': 'Mogadishu',
          'arrival_city': 'Garowe',
          'bus_number': 'MOG-GRW-08',
          'payment_status': 'completed',
          'checked_in': false,
        };
      }

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
        'checked_in': response['payment_status'] == 'completed', // Check check-in rules
      };
    } catch (e) {
      _logger.w('Failed validating ticket: $e');
      return _mockBookings.values.first;
    }
  }

  // 2. Perform Check-In (Manual or QR)
  Future<void> checkInPassenger(String bookingId, bool isCheckedIn) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _logger.i('Mock Check-in passenger: $bookingId -> $isCheckedIn');
        for (var booking in _mockBookings.values) {
          if (booking['id'] == bookingId) {
            booking['checked_in'] = isCheckedIn;
          }
        }
        return;
      }
      await _supabase
          .from('bookings')
          .update({'payment_status': isCheckedIn ? 'completed' : 'pending'})
          .eq('id', bookingId);
    } catch (e) {
      _logger.e('Failed checking in passenger: $e');
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
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _logger.i('Mock Luggage added: Tag $tagNumber, Weight $weight kg');
        _mockLuggage.add({
          'booking_id': bookingId,
          'trip_id': tripId,
          'tag_number': tagNumber,
          'weight_kg': weight,
          'pieces': pieces,
          'status': 'loaded',
          'created_at': DateTime.now().toIso8601String(),
        });
        return;
      }
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
      throw Exception('Database submission failed');
    }
  }

  // 4. Load Luggage list for a trip
  Future<List<Map<String, dynamic>>> getLuggageList(String tripId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        return _mockLuggage.isNotEmpty ? _mockLuggage : [
          {'tag_number': 'LUG-098877', 'weight_kg': 15.5, 'pieces': 1, 'status': 'loaded', 'booking_id': 'booking-uuid-1'},
          {'tag_number': 'LUG-120093', 'weight_kg': 25.0, 'pieces': 2, 'status': 'delivered', 'booking_id': 'booking-uuid-2'},
        ];
      }
      final response = await _supabase.from('luggage').select('*').eq('trip_id', tripId);
      return (response as List).map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Luggage query failed, returning mockup list: $e');
      return [
        {'tag_number': 'LUG-098877', 'weight_kg': 15.5, 'pieces': 1, 'status': 'loaded', 'booking_id': 'booking-uuid-1'},
        {'tag_number': 'LUG-120093', 'weight_kg': 25.0, 'pieces': 2, 'status': 'delivered', 'booking_id': 'booking-uuid-2'},
      ];
    }
  }

  // 5. Staff Attendance (Clock In / Clock Out)
  Future<void> recordAttendance({
    required String userId,
    required String status,
    required bool checkIn,
  }) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _logger.i('Mock attendance action: userId $userId, status $status, checkIn $checkIn');
        if (checkIn) {
          _mockAttendance.add({
            'user_id': userId,
            'date': DateTime.now().toIso8601String().substring(0, 10),
            'check_in': DateTime.now().toIso8601String(),
            'status': status,
          });
        } else {
          final idx = _mockAttendance.indexWhere((element) => element['user_id'] == userId);
          if (idx != -1) {
            _mockAttendance[idx]['check_out'] = DateTime.now().toIso8601String();
          }
        }
        return;
      }

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
      _logger.e('Failed to record staff attendance: $e');
    }
  }

  // 6. Read Staff Attendance Status
  Future<Map<String, dynamic>?> getTodayAttendance(String userId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        final match = _mockAttendance.firstWhere(
          (element) => element['user_id'] == userId, 
          orElse: () => <String, dynamic>{},
        );
        return match.isEmpty ? null : match;
      }
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final response = await _supabase
          .from('attendance')
          .select('*')
          .match({'user_id': userId, 'date': dateStr})
          .maybeSingle();
      return response;
    } catch (e) {
      _logger.w('Attendance status query failed: $e');
      return null;
    }
  }
}
