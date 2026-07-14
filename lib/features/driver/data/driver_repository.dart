import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:logger/logger.dart';
import '../../../../core/shared/services/supabase_service.dart';
import '../../../../core/shared/utils/logger.dart';
import '../../../../core/config/constants.dart';
import '../../booking/data/models/trip.dart';

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider).client;
  final logger = ref.watch(loggerProvider);
  return DriverRepository(supabase, logger);
});

class DriverRepository {
  final sb.SupabaseClient _supabase;
  final Logger _logger;

  DriverRepository(this._supabase, this._logger);

  // In-memory cache mock data
  final List<Trip> _mockTrips = [
    Trip(
      id: 'd9b8a7c6-2222-3333-4444-555566667777',
      routeId: 'e6c86a1b-6406-4dfc-a496-e1376f9d2d0a',
      departureCity: 'Mogadishu',
      arrivalCity: 'Garowe',
      departureTime: DateTime.now().add(const Duration(hours: 1)),
      arrivalTime: DateTime.now().add(const Duration(hours: 9)),
      busNumber: 'MOG-GRW-08',
      totalSeats: 40,
      availableSeats: 36,
      occupiedSeats: const ['A1', 'A2', 'B3', 'B4'],
      price: 25.0,
    ),
    Trip(
      id: 'c8b7a6d5-4444-5555-6666-777788889999',
      routeId: 'a7f6c3d8-1111-2222-3333-444455556666',
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
  ];

  final List<Map<String, dynamic>> _mockIncidentReports = [];
  final List<Map<String, dynamic>> _mockFuelReports = [];
  
  // Real-time GPS Tracker state
  double currentLat = 2.0469;
  double currentLng = 45.3182;

  // 1. Fetch Today's Trips for driver
  Future<List<Trip>> getTodayTrips(String driverId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 500));
        return _mockTrips;
      }
      final response = await _supabase
          .from('trips')
          .select('*, routes(*)')
          .eq('driver_id', driverId)
          .gte('departure_time', DateTime.now().toIso8601String().substring(0, 10));
      return (response as List).map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      _logger.w('Supabase query failed, falling back to mock driver trips: $e');
      return _mockTrips;
    }
  }

  // 2. Fetch Trip Passengers (Bookings)
  Future<List<Map<String, dynamic>>> getTripPassengers(String tripId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 300));
        return [
          {'name': 'Ahmed Ali', 'phone': '+252 61 5551234', 'seats': ['A1', 'A2'], 'checkedIn': true},
          {'name': 'Faiza Warsame', 'phone': '+252 61 7773344', 'seats': ['B3'], 'checkedIn': false},
          {'name': 'Mohamed Farah', 'phone': '+252 61 9998877', 'seats': ['B4'], 'checkedIn': true},
        ];
      }

      final response = await _supabase
          .from('bookings')
          .select('id, seats, payment_status, profiles(full_name, phone_number)')
          .eq('trip_id', tripId);
      
      return (response as List).map((json) {
        final profile = json['profiles'] as Map<String, dynamic>? ?? {};
        return {
          'booking_id': json['id'],
          'name': profile['full_name'] ?? 'Somali Commuter',
          'phone': profile['phone_number'] ?? '',
          'seats': (json['seats'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          'checkedIn': json['payment_status'] == 'completed',
        };
      }).toList();
    } catch (e) {
      _logger.w('Supabase bookings query failed: $e');
      return [
        {'name': 'Ahmed Ali', 'phone': '+252 61 5551234', 'seats': ['A1', 'A2'], 'checkedIn': true},
        {'name': 'Faiza Warsame', 'phone': '+252 61 7773344', 'seats': ['B3'], 'checkedIn': false},
        {'name': 'Mohamed Farah', 'phone': '+252 61 9998877', 'seats': ['B4'], 'checkedIn': true},
      ];
    }
  }

  // 3. Update Trip Status
  Future<void> updateTripStatus(String tripId, String status) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _logger.i('Mock update trip status: $tripId -> $status');
        return;
      }
      await _supabase.from('trips').update({'status': status}).eq('id', tripId);
    } catch (e) {
      _logger.e('Failed to update trip status: $e');
    }
  }

  // 4. Update GPS Location
  Future<void> updateGPSLocation({
    required String busNumber,
    required double latitude,
    required double longitude,
    required double speed,
    required double fuelLevel,
    required int passengerCount,
  }) async {
    currentLat = latitude;
    currentLng = longitude;
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _logger.i('Mock GPS Broadcaster: Lat $latitude, Lng $longitude, Speed $speed, Fuel $fuelLevel, Passengers $passengerCount');
        return;
      }
      await _supabase.from('buses').update({
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'fuel_level': fuelLevel,
        'passenger_count': passengerCount,
        'last_gps_update': DateTime.now().toIso8601String(),
      }).eq('bus_number', busNumber);
    } catch (e) {
      _logger.e('Failed updating GPS table in Supabase: $e');
    }
  }

  // 5. Submit Fuel Report
  Future<void> submitFuelReport({
    required String busNumber,
    required String driverId,
    required double liters,
    required double cost,
    required double odometer,
  }) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockFuelReports.add({
          'bus_number': busNumber,
          'driver_id': driverId,
          'amount_liters': liters,
          'cost': cost,
          'odometer_reading': odometer,
          'created_at': DateTime.now().toIso8601String(),
        });
        return;
      }
      await _supabase.from('fuel_reports').insert({
        'bus_number': busNumber,
        'driver_id': driverId,
        'amount_liters': liters,
        'cost': cost,
        'odometer_reading': odometer,
      });
    } catch (e) {
      _logger.e('Failed to insert fuel report: $e');
      throw Exception('Database submission failed');
    }
  }

  // 6. Submit Incident Report
  Future<void> submitIncidentReport({
    required String tripId,
    required String driverId,
    required String severity,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockIncidentReports.add({
          'trip_id': tripId,
          'driver_id': driverId,
          'severity': severity,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
          'created_at': DateTime.now().toIso8601String(),
        });
        return;
      }
      await _supabase.from('incident_reports').insert({
        'trip_id': tripId,
        'driver_id': driverId,
        'severity': severity,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      _logger.e('Failed to insert incident report: $e');
      throw Exception('Database submission failed');
    }
  }

  // 7. Fetch Trip History
  Future<List<Trip>> getTripHistory(String driverId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 400));
        return _mockTrips;
      }
      final response = await _supabase
          .from('trips')
          .select('*, routes(*)')
          .eq('driver_id', driverId)
          .lt('departure_time', DateTime.now().toIso8601String());
      return (response as List).map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      _logger.w('Failed query trip history, returning mocks: $e');
      return _mockTrips;
    }
  }
}
