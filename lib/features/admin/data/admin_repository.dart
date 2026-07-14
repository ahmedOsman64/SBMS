import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:logger/logger.dart';
import '../../../../core/shared/services/supabase_service.dart';
import '../../../../core/shared/utils/logger.dart';
import '../../../../core/config/constants.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider).client;
  final logger = ref.watch(loggerProvider);
  return AdminRepository(supabase, logger);
});

class AdminRepository {
  final sb.SupabaseClient _supabase;
  final Logger _logger;

  AdminRepository(this._supabase, this._logger);

  // --- LOCAL CACHE MOCK DATABASES FOR DEVELOPMENT FALLBACKS ---
  final List<Map<String, dynamic>> _mockCompanies = [
    {'id': 'c-1', 'name': 'Soomaal Transit Corp', 'legal_name': 'Soomaal Transit Corporation Ltd', 'registration_number': 'STC-100293', 'contact_email': 'info@soomaaltransit.so', 'contact_phone': '+252 61 2221122', 'status': 'active'},
    {'id': 'c-2', 'name': 'Puntland Express', 'legal_name': 'Puntland Bus Service Express', 'registration_number': 'PEX-998811', 'contact_email': 'contact@puntexpress.so', 'contact_phone': '+252 90 7773344', 'status': 'active'},
  ];

  final List<Map<String, dynamic>> _mockBranches = [
    {'id': 'b-1', 'company_id': 'c-1', 'name': 'Mogadishu Central Station', 'code': 'MOG-CEN', 'city': 'Mogadishu', 'contact_phone': '+252 61 5556677', 'manager_name': 'Dahir Gure', 'status': 'active'},
    {'id': 'b-2', 'company_id': 'c-2', 'name': 'Garowe Main Hub', 'code': 'GRW-HUB', 'city': 'Garowe', 'contact_phone': '+252 90 8881122', 'manager_name': 'Faduma Elmi', 'status': 'active'},
  ];

  final List<Map<String, dynamic>> _mockCoupons = [
    {'id': 'cp-1', 'code': 'SOMALIDIASPORA', 'discount_percent': 15.0, 'max_discount_usd': 10.0, 'valid_from': '2026-07-01', 'valid_to': '2026-08-31', 'usage_limit': 500, 'used_count': 120, 'is_active': true},
    {'id': 'cp-2', 'code': 'XAGAA2026', 'discount_percent': 20.0, 'max_discount_usd': 5.0, 'valid_from': '2026-07-10', 'valid_to': '2026-07-20', 'usage_limit': 100, 'used_count': 94, 'is_active': true},
  ];

  final List<Map<String, dynamic>> _mockSupportTickets = [
    {'id': 'st-1', 'passenger_name': 'Hassan Ali', 'subject': 'Double payment EVC Plus', 'category': 'payment', 'priority': 'high', 'status': 'open', 'created_at': '2026-07-12'},
    {'id': 'st-2', 'passenger_name': 'Sahra Osman', 'subject': 'Delayed departure Mogadishu', 'category': 'booking', 'priority': 'medium', 'status': 'in_progress', 'created_at': '2026-07-13'},
  ];

  final List<Map<String, dynamic>> _mockAuditLogs = [
    {'id': 'log-1', 'user_email': 'admin@sbms.so', 'action': 'CREATE_COUPON', 'table_name': 'coupons', 'record_id': 'cp-2', 'ip_address': '197.220.33.14', 'created_at': '2026-07-13 09:20:00'},
    {'id': 'log-2', 'user_email': 'manager@soomaal.so', 'action': 'ASSIGN_DRIVER', 'table_name': 'trips', 'record_id': 'd9b8a7c6-2222', 'ip_address': '197.220.33.19', 'created_at': '2026-07-13 10:15:00'},
  ];

  // 1. --- COMPANIES CRUD ---
  Future<List<Map<String, dynamic>>> getCompanies() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 300));
        return _mockCompanies;
      }
      final response = await _supabase.from('companies').select('*');
      return (response as List).map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Supabase query failed, returning mockup companies: $e');
      return _mockCompanies;
    }
  }

  Future<void> addCompany(Map<String, dynamic> data) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockCompanies.add({
          'id': 'c-${DateTime.now().millisecondsSinceEpoch}',
          ...data,
        });
        return;
      }
      await _supabase.from('companies').insert(data);
    } catch (e) {
      _logger.e('Failed to add company in Supabase: $e');
      throw Exception('Database operation failed');
    }
  }

  Future<void> deleteCompany(String id) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockCompanies.removeWhere((c) => c['id'] == id);
        return;
      }
      await _supabase.from('companies').delete().eq('id', id);
    } catch (e) {
      _logger.e('Failed deleting company in Supabase: $e');
      throw Exception('Database operation failed');
    }
  }

  // 2. --- BRANCHES CRUD ---
  Future<List<Map<String, dynamic>>> getBranches() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 300));
        return _mockBranches;
      }
      final response = await _supabase.from('branches').select('*, companies(name)');
      return (response as List).map((json) {
        final row = json as Map<String, dynamic>;
        final comp = row['companies'] as Map<String, dynamic>? ?? {};
        return <String, dynamic>{
          ...row,
          'company_name': comp['name'] ?? 'Transit Operator',
        };
      }).toList();
    } catch (e) {
      _logger.w('Supabase query failed, returning mockup branches: $e');
      return _mockBranches;
    }
  }

  Future<void> addBranch(Map<String, dynamic> data) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockBranches.add({
          'id': 'b-${DateTime.now().millisecondsSinceEpoch}',
          ...data,
        });
        return;
      }
      await _supabase.from('branches').insert(data);
    } catch (e) {
      _logger.e('Failed to insert branch: $e');
      throw Exception('Database operation failed');
    }
  }

  Future<void> deleteBranch(String id) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockBranches.removeWhere((b) => b['id'] == id);
        return;
      }
      await _supabase.from('branches').delete().eq('id', id);
    } catch (e) {
      _logger.e('Failed deleting branch: $e');
      throw Exception('Database operation failed');
    }
  }

  // 3. --- PROMOTIONS / COUPONS CRUD ---
  Future<List<Map<String, dynamic>>> getCoupons() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 250));
        return _mockCoupons;
      }
      final response = await _supabase.from('coupons').select('*');
      return (response as List).map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Coupons query failed, returning mockups: $e');
      return _mockCoupons;
    }
  }

  Future<void> addCoupon(Map<String, dynamic> data) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockCoupons.add({
          'id': 'cp-${DateTime.now().millisecondsSinceEpoch}',
          'used_count': 0,
          'is_active': true,
          ...data,
        });
        return;
      }
      await _supabase.from('coupons').insert(data);
    } catch (e) {
      _logger.e('Failed to insert coupon: $e');
      throw Exception('Database operation failed');
    }
  }

  Future<void> deleteCoupon(String id) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockCoupons.removeWhere((cp) => cp['id'] == id);
        return;
      }
      await _supabase.from('coupons').delete().eq('id', id);
    } catch (e) {
      _logger.e('Failed to delete coupon: $e');
      throw Exception('Database operation failed');
    }
  }

  // 4. --- USERS DIRECTORY ---
  Future<List<Map<String, dynamic>>> getStaffDirectory(String role) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (role == 'driver') {
          return [
            {'id': 'driver-u1', 'full_name': 'Ali Gure', 'email': 'aligure@sbms.so', 'phone_number': '+252 61 5550011', 'role': 'driver', 'status': 'available'},
            {'id': 'driver-u2', 'full_name': 'Osman Kediye', 'email': 'osman.k@sbms.so', 'phone_number': '+252 61 7771122', 'role': 'driver', 'status': 'busy'},
          ];
        } else {
          return [
            {'id': 'cond-u1', 'full_name': 'Khadra Warsame', 'email': 'khadra@sbms.so', 'phone_number': '+252 61 9993311', 'role': 'conductor', 'status': 'available'},
            {'id': 'cond-u2', 'full_name': 'Abdi Salad', 'email': 'abdi.s@sbms.so', 'phone_number': '+252 61 4442233', 'role': 'conductor', 'status': 'busy'},
          ];
        }
      }

      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('role', role);
      return (response as List).map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Staff query failed, returning mockup list: $e');
      return [
        {'id': 'staff-1', 'full_name': 'Dahir Farah', 'email': 'dahir@sbms.so', 'phone_number': '+252 61 5551122', 'role': role, 'status': 'active'}
      ];
    }
  }

  Future<List<Map<String, dynamic>>> getPassengersDirectory() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 350));
        return [
          {'id': 'pass-u1', 'full_name': 'Ahmed Ali Moallim', 'email': 'ahmed@gmail.com', 'phone_number': '+252 61 5551234', 'wallet_balance': 100.00, 'created_at': '2026-07-10'},
          {'id': 'pass-u2', 'full_name': 'Halima Warsame', 'email': 'halima.w@gmail.com', 'phone_number': '+252 61 8882233', 'wallet_balance': 45.50, 'created_at': '2026-07-11'},
          {'id': 'pass-u3', 'full_name': 'Farah Osman', 'email': 'farah.o@gmail.com', 'phone_number': '+252 61 9993344', 'wallet_balance': 12.00, 'created_at': '2026-07-12'},
        ];
      }
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('role', 'passenger');
      return (response as List).map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Passengers query failed, returning mockups: $e');
      return [
        {'id': 'pass-1', 'full_name': 'Ahmed Ali Moallim', 'email': 'ahmed@gmail.com', 'phone_number': '+252 61 5551234', 'wallet_balance': 100.00, 'created_at': '2026-07-10'}
      ];
    }
  }

  // 5. --- FINANCE: PAYMENTS, REFUNDS & WALLET ---
  Future<List<Map<String, dynamic>>> getPayments() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 300));
        return [
          {'id': 'pay-1', 'booking_id': 'b-uuid-1', 'amount': 25.00, 'method': 'evc_plus', 'status': 'completed', 'date': '2026-07-12 14:30'},
          {'id': 'pay-2', 'booking_id': 'b-uuid-2', 'amount': 12.00, 'method': 'wallet', 'status': 'completed', 'date': '2026-07-13 08:15'},
        ];
      }
      final response = await _supabase.from('bookings').select('id, total_price, payment_method, payment_status, created_at');
      return (response as List).map((json) {
        return {
          'id': 'pay-${json['id'].toString().substring(0, 5)}',
          'booking_id': json['id'],
          'amount': (json['total_price'] as num).toDouble(),
          'method': json['payment_method'],
          'status': json['payment_status'],
          'date': (json['created_at'] as String).substring(0, 16).replaceAll('T', ' '),
        };
      }).toList();
    } catch (e) {
      _logger.w('Payments query failed: $e');
      return [
        {'id': 'pay-1', 'booking_id': 'b-uuid-1', 'amount': 25.00, 'method': 'evc_plus', 'status': 'completed', 'date': '2026-07-12 14:30'}
      ];
    }
  }

  Future<void> triggerRefund(String bookingId, double amount) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _logger.i('Mock refund triggered for booking: $bookingId, amount: \$$amount');
        return;
      }
      // Set booking payment_status to 'refunded'
      await _supabase.from('bookings').update({'payment_status': 'refunded'}).eq('id', bookingId);
      // Log transaction
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('wallet_transactions').insert({
          'user_id': userId,
          'amount': amount,
          'type': 'refund',
          'status': 'completed',
        });
      }
    } catch (e) {
      _logger.e('Failed dynamic refund processing: $e');
      throw Exception('Refund action failed');
    }
  }

  // 6. --- SECURITY & SYSTEM MONITORS ---
  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        return _mockAuditLogs;
      }
      final response = await _supabase.from('audit_logs').select('*').order('created_at', ascending: false);
      return (response as List).map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Audit logs query failed: $e');
      return _mockAuditLogs;
    }
  }

  // 7. --- SUPPORT TICKETS CONSOLE ---
  Future<List<Map<String, dynamic>>> getSupportTickets() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        return _mockSupportTickets;
      }
      final response = await _supabase.from('support_tickets').select('*');
      return (response as List).map((json) => json as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Support tickets query failed: $e');
      return _mockSupportTickets;
    }
  }

  Future<void> updateTicketStatus(String ticketId, String status) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        final idx = _mockSupportTickets.indexWhere((element) => element['id'] == ticketId);
        if (idx != -1) {
          _mockSupportTickets[idx]['status'] = status;
        }
        return;
      }
      await _supabase.from('support_tickets').update({'status': status}).eq('id', ticketId);
    } catch (e) {
      _logger.e('Failed ticket update: $e');
    }
  }

  // 8. --- AI SYSTEM FEATURES INTERFACE (Demand, dynamic, fraud) ---
  Future<List<Map<String, dynamic>>> getDemandPredictions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {'route': 'Mogadishu ➔ Garowe', 'peak_season': 'Summer/Hajj Diaspora', 'load_factor': '92%', 'predicted_passengers': 38, 'confidence': '89%'},
      {'route': 'Hargeisa ➔ Burao', 'peak_season': 'Normal', 'load_factor': '74%', 'predicted_passengers': 29, 'confidence': '94%'},
      {'route': 'Mogadishu ➔ Kismayo', 'peak_season': 'Weekend', 'load_factor': '88%', 'predicted_passengers': 35, 'confidence': '85%'},
    ];
  }

  Future<List<Map<String, dynamic>>> getDynamicPricingModifications() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return [
      {'route': 'Mogadishu ➔ Garowe', 'base_price': 25.0, 'load_factor': '92%', 'dynamic_modifier': '+2.50 USD', 'calculated_fare': 27.50, 'reason': 'High demand corridor load prediction'},
      {'route': 'Hargeisa ➔ Burao', 'base_price': 12.0, 'load_factor': '55%', 'dynamic_modifier': '-1.20 USD', 'calculated_fare': 10.80, 'reason': 'Off-peak seat clearance promo'},
    ];
  }

  Future<List<Map<String, dynamic>>> getFraudDetections() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return [
      {'id': 'frd-1', 'passenger': 'Ali Warsame', 'reason': 'Rapid wallet transaction attempts (5 fails)', 'risk_score': 'Critical (95%)', 'action': 'Temporarily lock wallet EVC api checks'},
      {'id': 'frd-2', 'passenger': 'Farah Ahmed', 'reason': 'Double booking reservation on conflicting routes', 'risk_score': 'Medium (68%)', 'action': 'Flagged for conductor review check-in'},
    ];
  }

  // 9. --- FILE EXPORTS INTEGRATIONS (PDF / EXCEL MOCK DUMMY EXPORT DOWNLOAD) ---
  Future<String> exportReport({required String reportType, required String format}) async {
    await Future.delayed(const Duration(seconds: 1));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'SBMS_Report_${reportType.toUpperCase()}_$timestamp.${format.toLowerCase()}';
    _logger.i('Generated export payload file: $filename');
    return filename; // Return generated filename for UI validation feedback
  }

  // ============================================================
  // 10. --- COMPANY-SCOPED QUERIES (Admin Company Manager) ---
  // ============================================================

  /// Returns summary statistics for a specific company (for Admin dashboard)
  Future<Map<String, dynamic>> getCompanyStats(String companyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      // Mock: return realistic stats scoped to this company
      return {
        'branch_count': 3,
        'driver_count': 8,
        'conductor_count': 6,
        'active_trips_today': 4,
        'total_revenue_month': 12450.00,
        'total_bookings_month': 312,
        'avg_occupancy': 78.5,
        'active_buses': 5,
      };
    } catch (e) {
      _logger.w('Failed getCompanyStats: $e');
      return {
        'branch_count': 0,
        'driver_count': 0,
        'conductor_count': 0,
        'active_trips_today': 0,
        'total_revenue_month': 0.0,
        'total_bookings_month': 0,
        'avg_occupancy': 0.0,
        'active_buses': 0,
      };
    }
  }

  /// Returns branches belonging to a specific company
  Future<List<Map<String, dynamic>>> getCompanyBranches(String companyId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 300));
        return [
          {
            'id': 'b-1',
            'name': 'Mogadishu Central Station',
            'code': 'MOG-CEN',
            'city': 'Mogadishu',
            'contact_phone': '+252 61 5556677',
            'manager_name': 'Dahir Gure',
            'status': 'active',
            'buses_count': 3,
          },
          {
            'id': 'b-2',
            'name': 'Garowe Hub Terminal',
            'code': 'GRW-HUB',
            'city': 'Garowe',
            'contact_phone': '+252 90 8881122',
            'manager_name': 'Faduma Elmi',
            'status': 'active',
            'buses_count': 2,
          },
          {
            'id': 'b-3',
            'name': 'Hargeisa North Gate',
            'code': 'HAR-NGT',
            'city': 'Hargeisa',
            'contact_phone': '+252 63 7772211',
            'manager_name': 'Omar Jama',
            'status': 'inactive',
            'buses_count': 0,
          },
        ];
      }
      final response = await _supabase
          .from('branches')
          .select('*')
          .eq('company_id', companyId);
      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Failed getCompanyBranches: $e');
      return [];
    }
  }

  /// Returns staff (drivers + conductors) belonging to a specific company
  Future<List<Map<String, dynamic>>> getCompanyStaff(String companyId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 300));
        return [
          {
            'id': 'driver-u1',
            'full_name': 'Ali Gure',
            'email': 'ali.gure@sbms.so',
            'phone_number': '+252 61 5550011',
            'role': 'driver',
            'status': 'on_duty',
            'branch': 'Mogadishu Central',
            'trips_completed': 142,
          },
          {
            'id': 'driver-u2',
            'full_name': 'Osman Kediye',
            'email': 'osman.k@sbms.so',
            'phone_number': '+252 61 7771122',
            'role': 'driver',
            'status': 'available',
            'branch': 'Garowe Hub',
            'trips_completed': 98,
          },
          {
            'id': 'driver-u3',
            'full_name': 'Ahmed Daud',
            'email': 'ahmed.d@sbms.so',
            'phone_number': '+252 61 3339988',
            'role': 'driver',
            'status': 'off_duty',
            'branch': 'Mogadishu Central',
            'trips_completed': 67,
          },
          {
            'id': 'cond-u1',
            'full_name': 'Khadra Warsame',
            'email': 'khadra.w@sbms.so',
            'phone_number': '+252 61 9993311',
            'role': 'conductor',
            'status': 'on_duty',
            'branch': 'Mogadishu Central',
            'trips_completed': 119,
          },
          {
            'id': 'cond-u2',
            'full_name': 'Abdi Salad',
            'email': 'abdi.s@sbms.so',
            'phone_number': '+252 61 4442233',
            'role': 'conductor',
            'status': 'available',
            'branch': 'Hargeisa North Gate',
            'trips_completed': 54,
          },
          {
            'id': 'cond-u3',
            'full_name': 'Faadumo Nur',
            'email': 'faadumo.n@sbms.so',
            'phone_number': '+252 61 2228877',
            'role': 'conductor',
            'status': 'off_duty',
            'branch': 'Garowe Hub',
            'trips_completed': 81,
          },
        ];
      }
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('company_id', companyId)
          .inFilter('role', ['driver', 'conductor']);
      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Failed getCompanyStaff: $e');
      return [];
    }
  }

  /// Returns trips scoped to a specific company with revenue/booking info
  Future<List<Map<String, dynamic>>> getCompanyTrips(String companyId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 350));
        return [
          {
            'id': 'trip-001',
            'route': 'Mogadishu ➔ Garowe',
            'bus_number': 'MOG-GRW-08',
            'driver_name': 'Ali Gure',
            'departure_time': '06:00',
            'status': 'completed',
            'booked_seats': 38,
            'total_seats': 40,
            'revenue': 950.00,
            'date': '2026-07-13',
          },
          {
            'id': 'trip-002',
            'route': 'Hargeisa ➔ Burao',
            'bus_number': 'HAR-BUR-02',
            'driver_name': 'Osman Kediye',
            'departure_time': '08:30',
            'status': 'en_route',
            'booked_seats': 22,
            'total_seats': 40,
            'revenue': 528.00,
            'date': '2026-07-13',
          },
          {
            'id': 'trip-003',
            'route': 'Mogadishu ➔ Kismayo',
            'bus_number': 'MOG-KIS-05',
            'driver_name': 'Ahmed Daud',
            'departure_time': '10:00',
            'status': 'scheduled',
            'booked_seats': 14,
            'total_seats': 40,
            'revenue': 336.00,
            'date': '2026-07-13',
          },
          {
            'id': 'trip-004',
            'route': 'Bosaso ➔ Garowe',
            'bus_number': 'BOS-GRW-01',
            'driver_name': 'Ali Gure',
            'departure_time': '13:00',
            'status': 'delayed',
            'booked_seats': 30,
            'total_seats': 40,
            'revenue': 720.00,
            'date': '2026-07-13',
          },
        ];
      }
      final response = await _supabase
          .from('trips')
          .select('*, bookings(count), buses(bus_number)')
          .eq('company_id', companyId)
          .order('departure_time', ascending: true);
      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Failed getCompanyTrips: $e');
      return [];
    }
  }

  /// Returns coupons created by/for a specific company
  Future<List<Map<String, dynamic>>> getCompanyCoupons(String companyId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 250));
        return [
          {
            'id': 'cp-10',
            'code': 'SOOMAAL15',
            'discount_percent': 15.0,
            'valid_from': '2026-07-01',
            'valid_to': '2026-07-31',
            'usage_limit': 200,
            'used_count': 87,
            'is_active': true,
          },
          {
            'id': 'cp-11',
            'code': 'XAGAA25',
            'discount_percent': 25.0,
            'valid_from': '2026-07-10',
            'valid_to': '2026-07-20',
            'usage_limit': 50,
            'used_count': 48,
            'is_active': true,
          },
        ];
      }
      final response = await _supabase
          .from('coupons')
          .select('*')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('Failed getCompanyCoupons: $e');
      return [];
    }
  }

  /// Creates a new coupon scoped to a company
  Future<void> addCompanyCoupon(String companyId, Map<String, dynamic> data) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockCoupons.add({
          'id': 'cp-${DateTime.now().millisecondsSinceEpoch}',
          'company_id': companyId,
          'used_count': 0,
          'is_active': true,
          ...data,
        });
        return;
      }
      await _supabase.from('coupons').insert({'company_id': companyId, ...data});
    } catch (e) {
      _logger.e('Failed addCompanyCoupon: $e');
      throw Exception('Database operation failed');
    }
  }

  /// Deactivates a coupon
  Future<void> deactivateCoupon(String couponId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        final idx = _mockCoupons.indexWhere((c) => c['id'] == couponId);
        if (idx != -1) _mockCoupons[idx]['is_active'] = false;
        return;
      }
      await _supabase.from('coupons').update({'is_active': false}).eq('id', couponId);
    } catch (e) {
      _logger.e('Failed deactivateCoupon: $e');
    }
  }

  // ============================================================
  // 11. --- SUPERADMIN: ADMIN MANAGEMENT ---
  // Only SuperAdmin can create / delete Admins.
  // In production, user creation uses a Supabase Edge Function
  // (admin API) so the password is server-side and never exposed.
  // ============================================================

  /// Mock admin list (in-memory for dev). Production: query `profiles` table.
  final List<Map<String, dynamic>> _mockAdmins = [
    {
      'id': 'admin-u1',
      'full_name': 'Dahir Hassan',
      'email': 'dahir.admin@sbms.so',
      'phone_number': '+252 61 1112233',
      'company_name': 'Soomaal Transit Corp',
      'status': 'active',
      'created_at': '2026-07-01',
    },
    {
      'id': 'admin-u2',
      'full_name': 'Maryam Farah',
      'email': 'maryam.admin@sbms.so',
      'phone_number': '+252 90 4445566',
      'company_name': 'Puntland Express',
      'status': 'active',
      'created_at': '2026-07-05',
    },
  ];

  /// Returns all admin users — SuperAdmin only.
  Future<List<Map<String, dynamic>>> getAdmins() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 300));
        return _mockAdmins;
      }
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('role', 'admin')
          .order('created_at', ascending: false);
      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('getAdmins failed, returning mock: $e');
      return _mockAdmins;
    }
  }

  /// Creates an admin account — SuperAdmin only.
  /// Production: call Supabase Edge Function `create-privileged-user`
  /// so that the service-role key stays server-side.
  Future<void> createAdmin(Map<String, dynamic> data) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockAdmins.add({
          'id': 'admin-${DateTime.now().millisecondsSinceEpoch}',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String().substring(0, 10),
          ...data,
        });
        return;
      }
      // Production: invoke Edge Function
      await _supabase.functions.invoke('create-privileged-user', body: {
        ...data,
        'role': 'admin',
      });
    } catch (e) {
      _logger.e('createAdmin failed: $e');
      throw Exception('Failed to create admin account');
    }
  }

  /// Deletes / deactivates an admin — SuperAdmin only.
  Future<void> deleteAdmin(String adminId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockAdmins.removeWhere((a) => a['id'] == adminId);
        return;
      }
      await _supabase.from('profiles').update({'status': 'inactive'}).eq('id', adminId);
    } catch (e) {
      _logger.e('deleteAdmin failed: $e');
      throw Exception('Failed to remove admin');
    }
  }

  // ============================================================
  // 12. --- ADMIN: STAFF CREATION (Driver & Conductor) ---
  // Admin creates drivers and conductors for their own company.
  // ============================================================

  /// Mock staff list for the admin's company
  final List<Map<String, dynamic>> _mockStaff = [
    {
      'id': 'driver-u1',
      'full_name': 'Ali Gure',
      'email': 'ali.gure@sbms.so',
      'phone_number': '+252 61 5550011',
      'role': 'driver',
      'status': 'active',
      'created_at': '2026-07-02',
    },
    {
      'id': 'cond-u1',
      'full_name': 'Khadra Warsame',
      'email': 'khadra.w@sbms.so',
      'phone_number': '+252 61 9993311',
      'role': 'conductor',
      'status': 'active',
      'created_at': '2026-07-03',
    },
  ];

  /// Returns all staff (drivers + conductors) the admin manages.
  Future<List<Map<String, dynamic>>> getManagedStaff() async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        await Future.delayed(const Duration(milliseconds: 300));
        return _mockStaff;
      }
      final currentUserId = _supabase.auth.currentUser?.id;
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('created_by', currentUserId ?? '')
          .inFilter('role', ['driver', 'conductor'])
          .order('created_at', ascending: false);
      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      _logger.w('getManagedStaff failed, returning mock: $e');
      return _mockStaff;
    }
  }

  /// Creates a driver or conductor account — Admin only.
  Future<void> createStaffMember(Map<String, dynamic> data) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockStaff.add({
          'id': '${data['role']}-${DateTime.now().millisecondsSinceEpoch}',
          'status': 'active',
          'created_at': DateTime.now().toIso8601String().substring(0, 10),
          ...data,
        });
        return;
      }
      // Production: Edge Function creates auth user + profiles row
      await _supabase.functions.invoke('create-privileged-user', body: data);
    } catch (e) {
      _logger.e('createStaffMember failed: $e');
      throw Exception('Failed to create staff member');
    }
  }

  /// Removes / deactivates a staff member — Admin only.
  Future<void> deleteStaffMember(String staffId) async {
    try {
      if (AppConstants.supabaseUrl.contains('your-project-id')) {
        _mockStaff.removeWhere((s) => s['id'] == staffId);
        return;
      }
      await _supabase.from('profiles').update({'status': 'inactive'}).eq('id', staffId);
    } catch (e) {
      _logger.e('deleteStaffMember failed: $e');
      throw Exception('Failed to remove staff member');
    }
  }

  /// Returns platform-wide stats for the SuperAdmin dashboard.
  Future<Map<String, dynamic>> getPlatformStats() async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return {
        'total_companies': 12,
        'total_admins': 8,
        'total_drivers': 47,
        'total_conductors': 35,
        'total_passengers': 2840,
        'active_trips_today': 24,
        'total_revenue_month': 98450.00,
        'total_bookings_month': 3284,
      };
    } catch (e) {
      _logger.w('getPlatformStats failed: $e');
      return {
        'total_companies': 0,
        'total_admins': 0,
        'total_drivers': 0,
        'total_conductors': 0,
        'total_passengers': 0,
        'active_trips_today': 0,
        'total_revenue_month': 0.0,
        'total_bookings_month': 0,
      };
    }
  }
}
