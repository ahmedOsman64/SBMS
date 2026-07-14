import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:logger/logger.dart';
import '../../../../core/shared/services/supabase_service.dart';
import '../../../../core/shared/utils/logger.dart';
import '../../../../core/config/constants.dart';

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider).client;
  final logger = ref.watch(loggerProvider);
  return FleetRepository(supabase, logger);
});

class FleetRepository {
  final sb.SupabaseClient _supabase;
  final Logger _logger;

  FleetRepository(this._supabase, this._logger);

  // Fallback mock database
  final List<Map<String, dynamic>> _mockBuses = [
    {
      'id': 'bus-1',
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
      'id': 'bus-2',
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
      'id': 'bus-3',
      'bus_number': 'MOG-KIS-05',
      'model': 'Toyota Coaster 2022',
      'capacity': 40,
      'status': 'maintenance',
      'fuel_level': 45.00,
      'latitude': 2.0469,
      'longitude': 45.3182,
      'speed': 0.00,
      'passenger_count': 0,
    },
    {
      'id': 'bus-4',
      'bus_number': 'MOG-GAL-01',
      'model': 'Toyota HiAce 2024',
      'capacity': 14,
      'status': 'out_of_service',
      'fuel_level': 12.00,
      'latitude': 5.1521,
      'longitude': 46.1996,
      'speed': 0.00,
      'passenger_count': 0,
    }
  ];

  final List<Map<String, dynamic>> _mockMaintenance = [
    {
      'id': 'maint-1',
      'bus_number': 'MOG-KIS-05',
      'description': 'Engine Oil Change & Filter Replacement',
      'cost': 150.00,
      'status': 'completed',
      'scheduled_date': '2026-07-10',
      'completion_date': '2026-07-10',
    },
    {
      'id': 'maint-2',
      'bus_number': 'MOG-GRW-08',
      'description': 'Front Brake Pad Replacement & Air Filter',
      'cost': 220.00,
      'status': 'pending',
      'scheduled_date': '2026-07-20',
      'completion_date': null,
    }
  ];

  final List<Map<String, dynamic>> _mockFuelReports = [
    {
      'bus_number': 'MOG-GRW-08',
      'driver_name': 'Ali Gure',
      'amount_liters': 75.0,
      'cost': 82.50,
      'odometer_reading': 152340.0,
      'date': '2026-07-11',
    },
    {
      'bus_number': 'HAR-BUR-02',
      'driver_name': 'Osman Kediye',
      'amount_liters': 42.0,
      'cost': 46.20,
      'odometer_reading': 98450.0,
      'date': '2026-07-12',
    }
  ];

  final List<Map<String, dynamic>> _mockDrivers = [
    {'id': 'driver-u1', 'full_name': 'Ali Gure', 'role': 'driver', 'status': 'available'},
    {'id': 'driver-u2', 'full_name': 'Osman Kediye', 'role': 'driver', 'status': 'busy'},
    {'id': 'driver-u3', 'full_name': 'Ahmed Daud', 'role': 'driver', 'status': 'available'},
  ];

  final List<Map<String, dynamic>> _mockConductors = [
    {'id': 'cond-u1', 'full_name': 'Khadra Warsame', 'role': 'conductor', 'status': 'available'},
    {'id': 'cond-u2', 'full_name': 'Abdi Salad', 'role': 'conductor', 'status': 'busy'},
  ];

  // 1. Fetch all buses
  Future<List<Map<String, dynamic>>> getBuses() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 400));
        return _mockBuses;
      }
      final response = await _supabase.from('buses').select('*');
      return (response as List).map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Failed query buses, returning mocks: $e');
      return _mockBuses;
    }
  }

  // 2. Fetch maintenance history logs
  Future<List<Map<String, dynamic>>> getMaintenanceRecords() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 300));
        return _mockMaintenance;
      }
      final response = await _supabase.from('maintenance_records').select('*').order('created_at', ascending: false);
      return (response as List).map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Failed query maintenance logs, returning mocks: $e');
      return _mockMaintenance;
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
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockMaintenance.add({
          'id': 'maint-${DateTime.now().millisecondsSinceEpoch}',
          'bus_number': busNumber,
          'description': description,
          'cost': cost,
          'status': status,
          'scheduled_date': scheduledDate,
          'completion_date': status == 'completed' ? scheduledDate : null,
        });
        // Update bus status if maintenance
        final busIdx = _mockBuses.indexWhere((element) => element['bus_number'] == busNumber);
        if (busIdx != -1 && status != 'completed') {
          _mockBuses[busIdx]['status'] = 'maintenance';
        }
        return;
      }
      await _supabase.from('maintenance_records').insert({
        'bus_number': busNumber,
        'description': description,
        'cost': cost,
        'scheduled_date': scheduledDate,
        'status': status,
      });
      // Optionally update buses table status
      if (status != 'completed') {
        await _supabase.from('buses').update({'status': 'maintenance'}).eq('bus_number', busNumber);
      }
    } catch (e) {
      _logger.e('Failed to schedule maintenance: $e');
      throw Exception('Database update failed');
    }
  }

  // 4. Fetch fuel expenditure reports
  Future<List<Map<String, dynamic>>> getFuelReports() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 300));
        return _mockFuelReports;
      }
      final response = await _supabase
          .from('fuel_reports')
          .select('*, profiles(full_name)');
      return (response as List).map((json) {
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
    } catch (e) {
      _logger.w('Fuel logs query failed, returning mockup list: $e');
      return _mockFuelReports;
    }
  }

  // 5. Get available driver lists
  Future<List<Map<String, dynamic>>> getAvailableStaff() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        return [..._mockDrivers, ..._mockConductors];
      }
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, role')
          .inFilter('role', ['driver', 'conductor']);
      return (response as List).map((e) {
        return {
          'id': e['id'],
          'full_name': e['full_name'],
          'role': e['role'],
          'status': 'available', // Simplification
        };
      }).toList();
    } catch (e) {
      _logger.w('Failed fetching staff: $e');
      return [..._mockDrivers, ..._mockConductors];
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
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _logger.i('Mock assign: Trip $tripId -> Bus $busNumber, Driver $driverId, Conductor $conductorId');
        return;
      }
      await _supabase.from('trips').update({
        'bus_number': busNumber,
        'driver_id': driverId,
        'conductor_id': conductorId,
      }).eq('id', tripId);
    } catch (e) {
      _logger.e('Failed allocating trip assignments: $e');
      throw Exception('Assignment failed');
    }
  }

  // 7. Subscribe to all Active Trips (Supabase Realtime Stream mapping)
  Stream<List<Map<String, dynamic>>> streamRealtimeGPS() {
    if (AppConstants.supabaseUrl.contains('your-project-id')) {
      // Mock stream emitting every 4 seconds simulating slight GPS drift!
      return Stream.periodic(const Duration(seconds: 4), (count) {
        // Drift coordinates slightly for effect!
        final list = <Map<String, dynamic>>[];
        for (var bus in _mockBuses) {
          if (bus['status'] == 'active') {
            final driftLat = (count % 2 == 0 ? 0.0003 : -0.0002) * (count % 5);
            final driftLng = (count % 2 == 0 ? -0.0001 : 0.0004) * (count % 5);
            bus['latitude'] = (bus['latitude'] as double) + driftLat;
            bus['longitude'] = (bus['longitude'] as double) + driftLng;
            // Occasional speed/passenger count variations
            bus['speed'] = 50.0 + (count % 15);
            if (count % 8 == 0) {
              bus['passenger_count'] = (bus['passenger_count'] as int) + 1;
              if (bus['passenger_count'] > 40) bus['passenger_count'] = 25;
            }
          }
          list.add({...bus});
        }
        return list;
      }).asBroadcastStream();
    }

    // Connect to Supabase Realtime via select Stream
    // We stream the trips table (which is synced in real-time) or buses table
    return _supabase
        .from('buses')
        .stream(primaryKey: ['id'])
        .map((event) {
          return event.map((e) => e).toList();
        });
  }
}
