import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../exceptions/failures.dart';
import '../utils/logger.dart';
import 'supabase_service.dart';

enum UserRole {
  passenger,
  driver,
  conductor,
  admin,
  superAdmin;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'conductor':
        return UserRole.conductor;
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
      case 'super_admin':
        return UserRole.superAdmin;
      case 'passenger':
      default:
        return UserRole.passenger;
    }
  }

  String get label {
    switch (this) {
      case UserRole.passenger:
        return 'Passenger';
      case UserRole.driver:
        return 'Driver';
      case UserRole.conductor:
        return 'Conductor';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  /// Dashboard route each role is redirected to after login
  String get dashboardRoute {
    switch (this) {
      case UserRole.superAdmin:
        return '/super-admin';
      case UserRole.admin:
        return '/admin-portal';
      case UserRole.driver:
        return '/driver-home';
      case UserRole.conductor:
        return '/conductor-home';
      case UserRole.passenger:
        return '/home';
    }
  }

  /// Whether this role can self-signup through the public register screen.
  /// Only passengers are allowed to self-register.
  bool get canSelfRegister => this == UserRole.passenger;
}

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final double walletBalance;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.walletBalance = 0.0,
  });

  factory AppUser.fromMetadata(User user, {double walletBalance = 0.0}) {
    final meta = user.userMetadata ?? {};
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: meta['full_name'] as String? ?? 'Somali Commuter',
      phoneNumber: meta['phone_number'] as String? ?? '',
      role: UserRole.fromString(meta['role'] as String?),
      walletBalance: walletBalance,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map, {String fallbackEmail = ''}) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String? ?? fallbackEmail,
      fullName: map['full_name'] as String? ?? 'Somali Commuter',
      phoneNumber: map['phone_number'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      walletBalance: (map['wallet_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final supabase = ref.watch(supabaseServiceProvider).client;
  final logger = ref.watch(loggerProvider);
  return AuthService(supabase, logger);
});

class AuthService {
  final SupabaseClient _supabase;
  final Logger _logger;

  AuthService(this._supabase, this._logger);

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  AppUser? get currentAppUser =>
      currentUser != null ? AppUser.fromMetadata(currentUser!) : null;

  Future<AppUser> fetchUserProfile(String userId, String fallbackEmail) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return AppUser.fromMap(response, fallbackEmail: fallbackEmail);
    } catch (e) {
      _logger.w('Failed to fetch user profile from DB: $e. Falling back to auth metadata.');
      final user = currentUser;
      if (user != null && user.id == userId) {
        return AppUser.fromMetadata(user);
      }
      rethrow;
    }
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthFailure('Login failed. User profile empty.');
      }

      try {
        return await fetchUserProfile(response.user!.id, response.user!.email ?? email);
      } catch (_) {
        return AppUser.fromMetadata(response.user!);
      }
    } catch (e) {
      throw FailureHandler.handleException(e, _logger);
    }
  }

  /// Public registration — ONLY for passengers.
  /// Drivers, conductors, and admins are created by privileged roles.
  Future<AppUser> register({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'role': UserRole.passenger.name, // always passenger
        },
      );

      if (response.user == null) {
        throw const AuthFailure('Registration failed.');
      }

      // Wait a short time for the database trigger to finish inserting the profile
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        return await fetchUserProfile(response.user!.id, response.user!.email ?? email);
      } catch (_) {
        return AppUser.fromMetadata(response.user!);
      }
    } catch (e) {
      throw FailureHandler.handleException(e, _logger);
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw FailureHandler.handleException(e, _logger);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw FailureHandler.handleException(e, _logger);
    }
  }

  Future<bool> verifyOTP({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );
      return response.user != null;
    } catch (e) {
      throw FailureHandler.handleException(e, _logger);
    }
  }
}

// Authentication notifier provider for clean architecture presentation layers
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.data(null)) {
    _init();
  }

  void _init() {
    final user = _authService.currentUser;
    if (user != null) {
      _loadProfileAsync(user);
    } else {
      state = const AsyncValue.data(null);
    }

    _authService.authStateChanges.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _loadProfileAsync(user);
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> _loadProfileAsync(User user) async {
    try {
      final appUser = await _authService.fetchUserProfile(user.id, user.email ?? '');
      state = AsyncValue.data(appUser);
    } catch (e) {
      state = AsyncValue.data(AppUser.fromMetadata(user));
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user =
          await _authService.login(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Public sign-up — passengers only.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.logout();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
