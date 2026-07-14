import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

enum ConnectivityStatus { online, offline }

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

class ConnectivityService {
  final InternetConnectionChecker _connectionChecker = InternetConnectionChecker.createInstance(
    checkInterval: const Duration(seconds: 5),
    checkTimeout: const Duration(seconds: 3),
  );

  Stream<ConnectivityStatus> get onConnectivityChanged {
    return _connectionChecker.onStatusChange.map((status) {
      switch (status) {
        case InternetConnectionStatus.connected:
          return ConnectivityStatus.online;
        case InternetConnectionStatus.disconnected:
          return ConnectivityStatus.offline;
        default:
          return ConnectivityStatus.online;
      }
    });
  }

  Future<bool> get isConnected async {
    return await _connectionChecker.hasConnection;
  }
}

// Reactive Connectivity Provider
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  
  // Emit initial state synchronously or quickly
  return service.onConnectivityChanged;
});
