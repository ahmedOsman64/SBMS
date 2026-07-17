import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class WalletTransaction {
  final String id;
  final double amount;
  final String type; // 'deposit' or 'payment'
  final DateTime date;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
  });
}

final walletServiceProvider = StateNotifierProvider<WalletService, double>((ref) {
  final supabase = ref.watch(supabaseServiceProvider).client;
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.valueOrNull?.id;
  return WalletService(supabase, userId);
});

class WalletService extends StateNotifier<double> {
  final SupabaseClient _supabase;
  final String? _userId;
  final List<WalletTransaction> _transactions = [];

  WalletService(this._supabase, this._userId) : super(0.0) {
    _loadBalance();
  }

  final String _balanceKey = 'wallet_balance';

  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  Future<void> _loadBalance() async {
    if (_userId == null) {
      state = 0.0;
      _transactions.clear();
      return;
    }

    try {
      // 1. Fetch balance from Supabase profiles table
      final profile = await _supabase
          .from('profiles')
          .select('wallet_balance')
          .eq('id', _userId)
          .single();
      state = (profile['wallet_balance'] as num?)?.toDouble() ?? 0.0;

      // 2. Fetch transaction logs from Supabase wallet_transactions table
      final txResponse = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      _transactions.clear();
      for (var tx in txResponse as List) {
        _transactions.add(
          WalletTransaction(
            id: tx['id'] as String,
            amount: (tx['amount'] as num).toDouble(),
            type: tx['type'] as String,
            date: DateTime.parse(tx['created_at'] as String),
          ),
        );
      }
    } catch (_) {
      // Fallback: Read balance from local storage Hive
      try {
        final box = Hive.box(AppConstants.hiveSettingsBox);
        state = box.get('${_balanceKey}_$_userId', defaultValue: 100.0) as double;
      } catch (_) {
        state = 0.0;
      }
    }
  }

  Future<void> deposit(double amount) async {
    if (_userId == null) return;
    
    final newState = state + amount;
    state = newState;

    try {
      // 1. Update profiles wallet_balance in Supabase
      await _supabase.from('profiles').update({
        'wallet_balance': newState,
      }).eq('id', _userId);

      // 2. Log deposit transaction in Supabase
      await _supabase.from('wallet_transactions').insert({
        'user_id': _userId,
        'amount': amount,
        'type': 'deposit',
        'status': 'completed',
      });
    } catch (_) {
      // Fallback: Update local Hive storage
      final box = Hive.box(AppConstants.hiveSettingsBox);
      await box.put('${_balanceKey}_$_userId', newState);
    }

    _transactions.insert(
      0,
      WalletTransaction(
        id: 'tx-dep-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        type: 'deposit',
        date: DateTime.now(),
      ),
    );
  }

  Future<bool> pay(double amount) async {
    if (_userId == null || state < amount) {
      return false; // Insufficient balance
    }

    final newState = state - amount;
    state = newState;

    try {
      // 1. Update profiles wallet_balance in Supabase
      await _supabase.from('profiles').update({
        'wallet_balance': newState,
      }).eq('id', _userId);

      // 2. Log payment transaction in Supabase
      await _supabase.from('wallet_transactions').insert({
        'user_id': _userId,
        'amount': amount,
        'type': 'booking_payment',
        'status': 'completed',
      });
    } catch (_) {
      // Fallback: Update local Hive storage
      final box = Hive.box(AppConstants.hiveSettingsBox);
      await box.put('${_balanceKey}_$_userId', newState);
    }

    _transactions.insert(
      0,
      WalletTransaction(
        id: 'tx-pay-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        type: 'payment',
        date: DateTime.now(),
      ),
    );
    return true;
  }
}
