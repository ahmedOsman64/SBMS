import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

class SupabaseService {
  late final SupabaseClient client;

  Future<void> initialize() async {
    // Initializing Supabase with default placeholders.
    // In production, these variables will load from environmental configs/constants.
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
    client = Supabase.instance.client;
  }
}
