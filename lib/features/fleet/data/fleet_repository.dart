import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:logger/logger.dart';
import '../../../../core/shared/services/supabase_service.dart';
import '../../../../core/shared/utils/logger.dart';

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider).client;
  final logger = ref.watch(loggerProvider);
  return FleetRepository(supabase, logger);
});

class FleetRepository {
  final sb.SupabaseClient _supabase;
  final Logger _logger;

  FleetRepository(this._supabase, this._logger);

  // 1. Fetch all buses
  Future<List<Map<String, dynamic>>> getBuses() async {
    try {
      final response = await _supabase.from('buses').select('*');
      final list = response as List;
      if (list.isEmpty) {
        // Seed default buses into database
        await _supabase.from('buses').insert([
          {
            'bus_number': 'MOG-GRW-08',
            'model': 'Toyota Coaster 2024',
            'capacity': 40,
            'status': 'active',
            'fuel_level': 85.00,
            'latitude': 2.0469,
            'longitude': 45.3182,
            'speed': 65.50,
            'passenger_count': 26,
          },
          {
            'bus_number': 'HAR-BUR-02',
            'model': 'Hyundai County 2023',
            'capacity': 40,
            'status': 'active',
            'fuel_level': 92.50,
            'latitude': 9.5627,
            'longitude': 44.0770,
            'speed': 40.00,
            'passenger_count': 18,
          },
          {
            'bus_number': 'MOG-KIS-05',
            'model': 'Toyota Coaster 2022',
            'capacity': 40,
            'status': 'maintenance',
            'fuel_level': 45.00,
            'latitude': 2.0469,
            'longitude': 45.3182,
            'speed': 0.00,
            'passenger_count': 0,
          }
        ]);
        final secondRes = await _supabase.from('buses').select('*');
        return List<Map<String, dynamic>>.from(secondRes);
      }
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      _logger.e('Failed to fetch buses from database: $e');
      rethrow;
    }
  }

  // 2. Fetch maintenance history logs
  Future<List<Map<String, dynamic>>> getMaintenanceRecords() async {
    try {
      final response = await _supabase.from('maintenance_records').select('*').order('created_at', ascending: false);
      final list = response as List;
      if (list.isEmpty) {
        await _supabase.from('maintenance_records').insert([
          {
            'bus_number': 'MOG-KIS-05',
            'description': 'Engine Oil Change & Filter Replacement',
            'cost': 150.00,
            'status': 'completed',
            'scheduled_date': '2026-07-10',
            'completion_date': '2026-07-10',
          },
          {
            'bus_number': 'MOG-GRW-08',
            'description': 'Front Brake Pad Replacement & Air Filter',
            'cost': 220.00,
            'status': 'pending',
            'scheduled_date': '2026-07-20',
            'completion_date': null,
          }
        ]);
        final secondRes = await _supabase.from('maintenance_records').select('*').order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(secondRes);
      }
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      _logger.e('Failed to fetch maintenance records: $e');
      rethrow;
    }
  }

  // 3. Schedule Maintenance
  Future<void> scheduleMaintenance({
    required String busNumber,
    required String description,
    required double cost,
    required String scheduledDate,
    required String status,
  }) async {
    try {
      await _supabase.from('maintenance_records').insert({
        'bus_number': busNumber,
        'description': description,
        'cost': cost,
        'scheduled_date': scheduledDate,
        'status': status,
      });
      if (status != 'completed') {
        await _supabase.from('buses').update({'status': 'maintenance'}).eq('bus_number', busNumber);
      }
    } catch (e) {
      _logger.e('Failed to schedule maintenance in database: $e');
      rethrow;
    }
  }

  // 4. Fetch fuel expenditure reports
  Future<List<Map<String, dynamic>>> getFuelReports() async {
    try {
      final response = await _supabase
          .from('fuel_reports')
          .select('*, profiles(full_name)');
      final list = response as List;
      if (list.isEmpty) {
        final profilesRes = await _supabase.from('profiles').select('id').eq('role', 'driver').limit(1);
        final profilesList = profilesRes as List;
        final driverId = profilesList.isNotEmpty ? profilesList.first['id'] : null;
        if (driverId != null) {
          await _supabase.from('fuel_reports').insert([
            {
              'bus_number': 'MOG-GRW-08',
              'driver_id': driverId,
              'amount_liters': 75.0,
              'cost': 82.50,
              'odometer_reading': 152340.0,
            },
            {
              'bus_number': 'HAR-BUR-02',
              'driver_id': driverId,
              'amount_liters': 42.0,
              'cost': 46.20,
              'odometer_reading': 98450.0,
            }
          ]);
          final secondRes = await _supabase
              .from('fuel_reports')
              .select('*, profiles(full_name)');
          return _formatFuel(secondRes as List);
        }
      }
      return _formatFuel(list);
    } catch (e) {
      _logger.e('Failed to fetch fuel reports: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _formatFuel(List list) {
    return list.map((json) {
      final profile = json['profiles'] as Map<String, dynamic>? ?? {};
      return {
        'bus_number': json['bus_number'],
        'driver_name': profile['full_name'] ?? 'Driver',
        'amount_liters': (json['amount_liters'] as num).toDouble(),
        'cost': (json['cost'] as num).toDouble(),
        'odometer_reading': (json['odometer_reading'] as num).toDouble(),
        'date': (json['created_at'] as String).substring(0, 10),
      };
    }).toList();
  }

  // 5. Get available driver lists
  Future<List<Map<String, dynamic>>> getAvailableStaff() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, role')
          .inFilter('role', ['driver', 'conductor']);
      return (response as List).map((e) {
        return {
          'id': e['id'],
          'full_name': e['full_name'],
          'role': e['role'],
          'status': 'available',
        };
      }).toList();
    } catch (e) {
      _logger.e('Failed to fetch staff list from database: $e');
      rethrow;
    }
  }

  // 6. Assign Driver, Conductor & Bus to Trip
  Future<void> assignTripStaffAndBus({
    required String tripId,
    required String busNumber,
    required String driverId,
    required String conductorId,
  }) async {
    try {
      await _supabase.from('trips').update({
        'bus_number': busNumber,
        'driver_id': driverId,
        'conductor_id': conductorId,
      }).eq('id', tripId);
    } catch (e) {
      _logger.e('Failed allocating trip assignments: $e');
      rethrow;
    }
  }

  // Register new bus
  Future<void> addBus(Map<String, dynamic> data) async {
    try {
      await _supabase.from('buses').insert(data);
    } catch (e) {
      _logger.e('Failed to register bus in database: $e');
      rethrow;
    }
  }

  // Delete registered bus
  Future<void> deleteBus(String busNumber) async {
    try {
      await _supabase.from('buses').delete().eq('bus_number', busNumber);
    } catch (e) {
      _logger.e('Failed to delete bus: $e');
      rethrow;
    }
  }

  // Update registered bus
  Future<void> updateBus(String busNumber, Map<String, dynamic> data) async {
    try {
      await _supabase.from('buses').update(data).eq('bus_number', busNumber);
    } catch (e) {
      _logger.e('Failed to update bus in database: $e');
      rethrow;
    }
  }

  // 7. Stream active GPS locations of buses
  Stream<List<Map<String, dynamic>>> streamRealtimeGPS() {
    return _supabase
        .from('buses')
        .stream(primaryKey: ['id'])
        .map((event) {
          return event.map((e) => e).toList();
        });
  }
}
