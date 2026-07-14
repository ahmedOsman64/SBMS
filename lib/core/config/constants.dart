class AppConstants {
  AppConstants._();

  // Application Details
  static const String appName = 'Smart Bus Booking & Fleet Management System';
  static const String appVersion = '1.0.0';

  // Supabase Configurations
  static const String supabaseUrl = 'https://zsuxufolwjspubvxqqof.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_W0D0oLNkxCQhp9B0qBh5UA_9HzJnDnm';

  // Local Storage Keys (Hive Boxes)
  static const String hiveSettingsBox = 'settings_box';
  static const String hiveSessionBox = 'session_box';
  static const String hiveCacheBox = 'cache_box';

  // Settings Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyIsOnboarded = 'is_onboarded';

  // Flutter Secure Storage Keys
  static const String secureKeyAuthToken = 'auth_token';
  static const String secureKeyRefreshToken = 'refresh_token';

  // Localisation Default Codes
  static const String localeEnglish = 'en';
  static const String localeSomali = 'so';
  
  // API Timeout
  static const int apiTimeoutSeconds = 30;
}
