import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../config/constants.dart';

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
  return WalletService();
});

class WalletService extends StateNotifier<double> {
  WalletService() : super(50.00) {
    _loadBalance();
  }

  final String _balanceKey = 'wallet_balance';
  final List<WalletTransaction> _transactions = [
    WalletTransaction(
      id: 'tx-1',
      amount: 50.00,
      type: 'deposit',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  void _loadBalance() {
    try {
      final box = Hive.box(AppConstants.hiveSettingsBox);
      final savedBalance = box.get(_balanceKey, defaultValue: 50.00) as double;
      state = savedBalance;
    } catch (_) {
      state = 50.00;
    }
  }

  Future<void> deposit(double amount) async {
    state += amount;
    
    _transactions.insert(
      0,
      WalletTransaction(
        id: 'tx-dep-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        type: 'deposit',
        date: DateTime.now(),
      ),
    );

    final box = Hive.box(AppConstants.hiveSettingsBox);
    await box.put(_balanceKey, state);
  }

  Future<bool> pay(double amount) async {
    if (state < amount) {
      return false; // Insufficient balance
    }
    state -= amount;
    
    _transactions.insert(
      0,
      WalletTransaction(
        id: 'tx-pay-${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        type: 'payment',
        date: DateTime.now(),
      ),
    );

    final box = Hive.box(AppConstants.hiveSettingsBox);
    await box.put(_balanceKey, state);
    return true;
  }
}
