import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../config/constants.dart';

final favoriteRoutesProvider = StateNotifierProvider<FavoriteRoutesService, List<String>>((ref) {
  return FavoriteRoutesService();
});

class FavoriteRoutesService extends StateNotifier<List<String>> {
  FavoriteRoutesService() : super([]) {
    _loadFavorites();
  }

  static const String _favoritesKey = 'favorite_routes_list';

  void _loadFavorites() {
    try {
      final box = Hive.box(AppConstants.hiveSettingsBox);
      final savedList = box.get(_favoritesKey, defaultValue: <String>[]) as List;
      state = savedList.cast<String>();
    } catch (_) {
      state = [];
    }
  }

  Future<void> toggleFavorite(String routeRepresentation) async {
    final list = List<String>.from(state);
    if (list.contains(routeRepresentation)) {
      list.remove(routeRepresentation);
    } else {
      list.add(routeRepresentation);
    }
    state = list;
    
    final box = Hive.box(AppConstants.hiveSettingsBox);
    await box.put(_favoritesKey, list);
  }

  bool isFavorite(String routeRepresentation) {
    return state.contains(routeRepresentation);
  }
}
