import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/config/theme.dart';
import 'core/config/theme_notifier.dart';
import 'core/config/router.dart';
import 'core/shared/localization/localization_provider.dart';
import 'core/shared/services/storage_service.dart';
import 'core/shared/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Local Storage (Hive & Secure Storage)
  final storageService = StorageService();
  try {
    await storageService.initialize();
  } catch (e) {
    debugPrint('StorageService initialization failed: $e');
  }

  // 2. Initialize Backend (Supabase client integration)
  final supabaseService = SupabaseService();
  try {
    await supabaseService.initialize();
  } catch (e) {
    debugPrint('SupabaseService initialization failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        // Override providers to supply initialized instances
        storageServiceProvider.overrideWithValue(storageService),
        supabaseServiceProvider.overrideWithValue(supabaseService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Somali Smart Bus Booking',
      debugShowCheckedModeBanner: false,
      
      // Dynamic Localisation Configs
      locale: locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('so', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
      ],
      
      // Dynamic Theme Configs
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Navigation Config
      routerConfig: router,
      
      // Responsive Breakpoints Layout wrapper
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
        ],
      ),
    );
  }
}

class FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return await GlobalMaterialLocalizations.delegate.load(const Locale('en', ''));
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

class FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) async {
    return await GlobalCupertinoLocalizations.delegate.load(const Locale('en', ''));
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}
