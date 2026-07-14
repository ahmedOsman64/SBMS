import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../config/constants.dart';
import 'translations.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale(AppConstants.localeEnglish)) {
    _loadLocale();
  }

  void _loadLocale() {
    try {
      final box = Hive.box(AppConstants.hiveSettingsBox);
      final languageCode = box.get(AppConstants.keyLanguage, defaultValue: AppConstants.localeEnglish);
      state = Locale(languageCode);
    } catch (_) {
      // Fallback if hive not initialized yet
      state = const Locale(AppConstants.localeEnglish);
    }
  }

  Future<void> setLocale(String languageCode) async {
    if (languageCode != AppConstants.localeEnglish && languageCode != AppConstants.localeSomali) {
      return;
    }
    state = Locale(languageCode);
    final box = Hive.box(AppConstants.hiveSettingsBox);
    await box.put(AppConstants.keyLanguage, languageCode);
  }

  void toggleLocale() {
    if (state.languageCode == AppConstants.localeEnglish) {
      setLocale(AppConstants.localeSomali);
    } else {
      setLocale(AppConstants.localeEnglish);
    }
  }
}

// Localization Helper extension for easy access in widgets
extension AppLocalizationsExtension on BuildContext {
  String tr(String key) {
    final container = ProviderScope.containerOf(this, listen: false);
    final locale = container.read(localeProvider);
    final translationsMap = AppTranslations.translations[locale.languageCode];
    if (translationsMap != null && translationsMap.containsKey(key)) {
      return translationsMap[key]!;
    }
    // Fallback to English if translation is missing
    final englishMap = AppTranslations.translations[AppConstants.localeEnglish];
    if (englishMap != null && englishMap.containsKey(key)) {
      return englishMap[key]!;
    }
    return key;
  }
}
