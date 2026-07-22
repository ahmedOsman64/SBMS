import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
    } catch (_) {}
    
    // Open default boxes safely
    final boxes = [
      AppConstants.hiveSettingsBox,
      AppConstants.hiveSessionBox,
      AppConstants.hiveCacheBox,
    ];
    for (final box in boxes) {
      try {
        if (!Hive.isBoxOpen(box)) {
          await Hive.openBox(box);
        }
      } catch (_) {}
    }
  }

  // --- Secure Storage (Tokens, Credentials) ---
  Future<void> saveSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> readSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
  }

  Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
  }

  // --- Hive General Box Operations ---
  Future<void> putData(String boxName, String key, dynamic value) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        await box.put(key, value);
      }
    } catch (_) {}
  }

  dynamic getData(String boxName, String key, {dynamic defaultValue}) {
    try {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        return box.get(key, defaultValue: defaultValue);
      }
    } catch (_) {}
    return defaultValue;
  }

  Future<void> deleteData(String boxName, String key) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        await box.delete(key);
      }
    } catch (_) {}
  }

  Future<void> clearBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        final box = Hive.box(boxName);
        await box.clear();
      }
    } catch (_) {}
  }
}
