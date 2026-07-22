import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

enum ConnectivityStatus { online, offline }

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

class ConnectivityService {
  final InternetConnectionChecker? _connectionChecker;

  ConnectivityService()
      : _connectionChecker = !kIsWeb
            ? InternetConnectionChecker.createInstance(
                checkInterval: const Duration(seconds: 5),
                checkTimeout: const Duration(seconds: 3),
              )
            : null;

  Stream<ConnectivityStatus> get onConnectivityChanged {
    if (kIsWeb) {
      // On Web, avoid background CORS-blocked HTTP pings that trigger browser_client debugger pauses
      return Stream.value(ConnectivityStatus.online);
    }
    return _connectionChecker?.onStatusChange.map((status) {
          switch (status) {
            case InternetConnectionStatus.connected:
              return ConnectivityStatus.online;
            case InternetConnectionStatus.disconnected:
              return ConnectivityStatus.offline;
            default:
              return ConnectivityStatus.online;
          }
        }) ??
        Stream.value(ConnectivityStatus.online);
  }

  Future<bool> get isConnected async {
    if (kIsWeb) {
      return true;
    }
    return await _connectionChecker?.hasConnection ?? true;
  }
}

// Reactive Connectivity Provider
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});
