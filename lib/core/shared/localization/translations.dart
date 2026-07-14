class AppTranslations {
  AppTranslations._();

  static const Map<String, Map<String, String>> translations = {
    'en': {
      // General
      'appName': 'Somali Smart Bus',
      'welcome': 'Welcome',
      'back': 'Back',
      'continue': 'Continue',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'retry': 'Retry',
      'loading': 'Loading...',
      'success': 'Success',
      'error': 'Error',
      'noConnection': 'No Internet Connection',
      'checkConnection': 'Please check your internet connection and try again.',

      // Roles
      'role_passenger': 'Passenger',
      'role_driver': 'Driver',
      'role_conductor': 'Conductor',
      'role_admin': 'Admin',
      'role_super_admin': 'Super Admin',

      // Onboarding
      'onboarding1_title': 'Smart Bus Booking',
      'onboarding1_desc': 'Book your tickets from anywhere in Somalia with secure and fast payments.',
      'onboarding2_title': 'Real-time Tracking',
      'onboarding2_desc': 'Track your bus in real-time and view accurate arrival times.',
      'onboarding3_title': 'Fleet Management',
      'onboarding3_desc': 'Enterprise solutions for drivers, conductors, and fleet owners.',
      'onboarding_get_started': 'Get Started',

      // Auth
      'login': 'Login',
      'login_title': 'Welcome Back',
      'login_subtitle': 'Enter your credentials to book your next ride',
      'register': 'Register',
      'register_title': 'Create Account',
      'register_subtitle': 'Sign up to get started with Somali Smart Bus',
      'email': 'Email Address',
      'email_hint': 'Enter your email',
      'password': 'Password',
      'password_hint': 'Enter your password',
      'confirm_password': 'Confirm Password',
      'confirm_password_hint': 'Re-enter your password',
      'forgot_password': 'Forgot Password?',
      'forgot_password_title': 'Reset Password',
      'forgot_password_subtitle': 'Enter your email to receive recovery instructions',
      'send_otp': 'Send Verification Code',
      'otp_verification': 'OTP Verification',
      'otp_subtitle': 'Enter the verification code sent to your device',
      'verify': 'Verify',
      'resend_otp': 'Resend Code',
      'already_have_account': 'Already have an account? Login',
      'dont_have_account': 'Don\'t have an account? Register',
      'select_role': 'Register As',
      'full_name': 'Full Name',
      'full_name_hint': 'Enter your full name',
      'phone_number': 'Phone Number',
      'phone_number_hint': 'e.g. 61xxxxxxx',
      'register_passenger_only': 'This registration is for Passengers only. Drivers, Conductors & Admins are created by authorised staff.',

      // Home
      'home': 'Home',
      'bookings': 'Bookings',
      'tickets': 'Tickets',
      'payments': 'Payments',
      'routes': 'Routes',
      'notifications': 'Notifications',
      'profile': 'Profile',
      'settings': 'Settings',

      // Form validation
      'field_required': 'This field is required',
      'invalid_email': 'Enter a valid email address',
      'invalid_phone': 'Enter a valid Somali phone number',
      'password_too_short': 'Password must be at least 6 characters',
      'passwords_dont_match': 'Passwords do not match',

      // Settings
      'language': 'Language',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'logout': 'Logout',
    },
    'so': {
      // General
      'appName': 'Gaariga Dadweynaha Soomaaliyeed',
      'welcome': 'Soo dhowow',
      'back': 'Dib u laabo',
      'continue': 'Sii wad',
      'save': 'Kaydi',
      'cancel': 'Ka laabo',
      'confirm': 'Xaqiiji',
      'retry': 'Isku day kale',
      'loading': 'Waa la rarayaa...',
      'success': 'Waa lagu guuleystay',
      'error': 'Cillad',
      'noConnection': 'Internet ma jiro',
      'checkConnection': 'Fadlan hubi khadkaaga internetka oo isku day markale.',

      // Roles
      'role_passenger': 'Rakaab',
      'role_driver': 'Darawal',
      'role_conductor': 'Kondiktoor',
      'role_admin': 'Maamule',
      'role_super_admin': 'Maamule Sare',

      // Onboarding
      'onboarding1_title': 'Boos Qabsasho Fudud',
      'onboarding1_desc': 'Ka gooso tigidhkaaga meel kasta oo aad joogto Soomaaliya adoo adeegsanaya lacag bixin sugan.',
      'onboarding2_title': 'Lasocoshada Tooska Ah',
      'onboarding2_desc': 'La soco halka uu marayo gaarigaaga wakhti kasta oo toos ah.',
      'onboarding3_title': 'Maamulka Gawaarida',
      'onboarding3_desc': 'Xalal casri ah oo loogu talagalay darawallada, kondiktoorrada, iyo milkiilayaasha gawaarida.',
      'onboarding_get_started': 'Biloow',

      // Auth
      'login': 'Soo gal',
      'login_title': 'Kusoo Dhawaada',
      'login_subtitle': 'Geli faahfaahintaada si aad u qabsato safarkaaga xiga',
      'register': 'Diiwanggeli',
      'register_title': 'Abuur Koonto',
      'register_subtitle': 'Isku diiwanggeli si aad u bilaawdo adeegga gaariga dadweynaha',
      'email': 'Cinwaanka Email-ka',
      'email_hint': 'Geli email-kaaga',
      'password': 'Erayga Sirta ah',
      'password_hint': 'Geli erayga sirta ah',
      'confirm_password': 'Hubi Erayga Sirta ah',
      'confirm_password_hint': 'Geli erayga sirta ah markale',
      'forgot_password': 'Ma ilaawday Eraygii Sirta ahaa?',
      'forgot_password_title': 'Dib u dajin Erayga Sirta',
      'forgot_password_subtitle': 'Geli email-kaaga si lagugu soo diro tilmaamaha dib u dajinta',
      'send_otp': 'Soo dir koodka xaqiijinta',
      'otp_verification': 'Xaqiijinta OTP',
      'otp_subtitle': 'Geli koodka xaqiijinta ee laguugu soo diray qalabkaaga',
      'verify': 'Xaqiiji',
      'resend_otp': 'Dib u dir koodka',
      'already_have_account': 'Horay miyaad u lahayd koonto? Soo gal',
      'dont_have_account': 'Miyaanad lahayn koonto? Diiwanggeli',
      'select_role': 'U diiwanggeli sidii',
      'full_name': 'Halkaada Magac',
      'full_name_hint': 'Geli magacaaga oo buuxa',
      'phone_number': 'Lambarka Taleefanka',
      'phone_number_hint': 'Tusaale. 61xxxxxxx',
      'register_passenger_only': 'Diiwaangelintani waxay u taalo Rakaabka oo keliya. Darawallada, Kondiktoorrada & Maamulayaasha waxaa abuuraa shaqaalaha oggolaanshaha leh.',

      // Home
      'home': 'Hoyga',
      'bookings': 'Ballamaha',
      'tickets': 'Tigidhada',
      'payments': 'Lacagaha',
      'routes': 'Waddooyinka',
      'notifications': 'Ogeysiisyada',
      'profile': 'Halkaan Ka Eeg Profile-ka',
      'settings': 'Habeeynta',

      // Form validation
      'field_required': 'Goobtani waa qasab',
      'invalid_email': 'Fadlan geli email sax ah',
      'invalid_phone': 'Geli lambar taleefan Soomaali ah oo sax ah',
      'password_too_short': 'Erayga sirta ah waa inuu ka koobnaadaa ugu yaraan 6 xaraf',
      'passwords_dont_match': 'Erayada sirta ah isma laha',

      // Settings
      'language': 'Luqadda',
      'theme': 'Muuqaalka',
      'dark_mode': 'Habka Madow',
      'light_mode': 'Habka Cad',
      'logout': 'Ka bax koontada',
    }
  };
}
