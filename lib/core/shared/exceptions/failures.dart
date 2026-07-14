import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class Failure implements Exception {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}

// Exception Handler Utility
class FailureHandler {
  FailureHandler._();

  static Failure handleException(dynamic exception, Logger logger) {
    logger.e('Exception encountered: $exception');
    
    // Extract message if it is a Failure, or use toString()
    String message = '';
    String? originalCode;
    
    if (exception is Failure) {
      message = exception.message;
      originalCode = exception.code;
    } else if (exception is AuthException) {
      message = exception.message;
      originalCode = 'AUTH_ERR';
    } else {
      message = exception.toString();
    }
    
    final lowerMsg = message.toLowerCase();
    
    // 1. Map rate limits
    if (lowerMsg.contains('rate limit')) {
      return const AuthFailure(
        'Aad ayaad u isku dayday marar badan. Fadlan sug waxyar ka hor inta aadan isku dayin mar kale. / Too many attempts. Please wait a few minutes before trying again.',
        code: 'RATE_LIMIT_ERR',
      );
    }
    
    // 2. Map invalid login credentials
    if (lowerMsg.contains('invalid login credentials') || lowerMsg.contains('invalid credentials') || lowerMsg.contains('invalid email or password')) {
      return const AuthFailure(
        'Email-ka ama Password-ka aad gelisay waa khalad. Fadlan dib u hubi. / Incorrect email or password. Please check your credentials.',
        code: 'INVALID_CREDENTIALS',
      );
    }
    
    // 3. Map duplicate registration
    if (lowerMsg.contains('user already registered') || lowerMsg.contains('already exists')) {
      return const AuthFailure(
        'Email-kaan horay ayaa loo diiwaan geliyay. Fadlan isticmaal email kale ama soo gal (Login). / This email is already registered. Please log in or use another email.',
        code: 'USER_EXISTS',
      );
    }
    
    // 4. Map weak password
    if (lowerMsg.contains('password should be') || lowerMsg.contains('weak password')) {
      return const AuthFailure(
        'Erayga sirta ah (Password) waa inuu ka koobnaadaa ugu yaraan 6 xaraf. / Password must be at least 6 characters long.',
        code: 'WEAK_PASSWORD',
      );
    }
    
    // 5. Map insufficient wallet balance (insufficient balance / wallet)
    if (lowerMsg.contains('insufficient wallet balance') || lowerMsg.contains('insufficient balance')) {
      return const ValidationFailure(
        'Haraagaaga (Wallet) kuma filna safarkaan. Fadlan ku dar lacag ama dooro qaab kale. / Insufficient wallet balance. Please top up or choose another payment method.',
        code: 'INSUFFICIENT_BALANCE',
      );
    }
    
    // 6. Map double booking / seat already reserved
    if (lowerMsg.contains('already reserved') || lowerMsg.contains('double booking') || lowerMsg.contains('have just been reserved')) {
      return const ValidationFailure(
        'Mid ama ka badan oo ka mid ah kuraasta aad dooratay horay ayaa loo qabsaday. Fadlan dooro kursi kale. / One or more selected seats are already reserved. Please select another seat.',
        code: 'SEATS_RESERVED',
      );
    }
    
    // 7. Map invalid trip session
    if (lowerMsg.contains('trip session') || lowerMsg.contains('seats selection is invalid')) {
      return const ValidationFailure(
        'Safarka ama doorashada kuraastu ma saxna. Fadlan dib u tiri. / Trip session or seats selection is invalid.',
        code: 'INVALID_SESSION',
      );
    }
    
    // 8. Map signup disabled
    if (lowerMsg.contains('signup is disabled')) {
      return const AuthFailure(
        'Diiwaangelinta cusub hadda waa la joojiyay. Fadlan la xiriir maamulka. / New registrations are currently disabled. Please contact support.',
        code: 'SIGNUP_DISABLED',
      );
    }
    
    // 9. Map email not confirmed
    if (lowerMsg.contains('email not confirmed') || lowerMsg.contains('not confirmed')) {
      return const AuthFailure(
        'Fadlan marka hore xaqiiji email-kaaga adoo isticmaalaya koodka laguugu soo diray. / Please confirm your email using the verification code first.',
        code: 'EMAIL_NOT_CONFIRMED',
      );
    }

    // 10. Map login/registration failures
    if (lowerMsg.contains('login failed') || lowerMsg.contains('user profile empty')) {
      return const AuthFailure(
        'Soo galitaanku waa uu guuldareystay. Profile-ka isticmaalaha lama helin. / Login failed. User profile empty.',
        code: 'LOGIN_FAILED',
      );
    }
    if (lowerMsg.contains('registration failed')) {
      return const AuthFailure(
        'Diiwaangelintu waa ay guuldareysatay. Fadlan dib isku day. / Registration failed. Please try again.',
        code: 'REGISTRATION_FAILED',
      );
    }

    // If it was already a Failure but didn't match the specific string replacements above, return as is
    if (exception is Failure) {
      return exception;
    }
    
    // General fallback mappings
    if (lowerMsg.contains('socketexception') || lowerMsg.contains('network') || lowerMsg.contains('handshake')) {
      return const NetworkFailure(
        'Khadkaaga internet-ka ma fiicna ama server-ka ayaan la xiriiri la\'nahay. Fadlan hubi internet-kaada. / No internet connection or server is unreachable.',
        code: 'NETWORK_ERR',
      );
    }
    
    if (lowerMsg.contains('supabaseexception') || lowerMsg.contains('postgrest') || lowerMsg.contains('database') || lowerMsg.contains('postgres')) {
      return const ServerFailure(
        'Cillad farsamo ayaa ka jirta dhanka database-ka. Fadlan dib isku day waxyar kadib. / Database server encountered an issue. Please try again soon.',
        code: 'DB_ERR',
      );
    }
    
    return UnknownFailure(
      'Cillad aan la garanayn ayaa dhacday. Fadlan isku day markale. / An unexpected error occurred. Please try again.',
      code: originalCode ?? 'UNKNOWN_ERR',
    );
  }
}
