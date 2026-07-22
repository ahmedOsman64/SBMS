import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

class SupabaseService {
  SupabaseClient? _client;

  SupabaseClient get client {
    if (_client != null) return _client!;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return SupabaseClient(
        AppConstants.supabaseUrl,
        AppConstants.supabaseAnonKey,
      );
    }
  }

  Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        publishableKey: AppConstants.supabaseAnonKey,
      );
      _client = Supabase.instance.client;
    } catch (e) {
      debugPrint('Supabase initialize error: $e');
      try {
        _client = Supabase.instance.client;
      } catch (_) {
        _client = SupabaseClient(
          AppConstants.supabaseUrl,
          AppConstants.supabaseAnonKey,
        );
      }
    }
  }
}
