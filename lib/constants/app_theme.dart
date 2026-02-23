// lib/constants/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary       = Color(0xFF2E7D32);
  static const Color primaryLight  = Color(0xFF4CAF50);
  static const Color primaryDark   = Color(0xFF1B5E20);
  static const Color accent        = Color(0xFFF9A825);
  static const Color accentLight   = Color(0xFFFFD54F);
  static const Color accentDark    = Color(0xFFF57F17);
  static const Color earth         = Color(0xFF795548);
  static const Color earthLight    = Color(0xFFA1887F);
  static const Color background    = Color(0xFFF5F5F5);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color divider       = Color(0xFFE0E0E0);
  static const Color textPrimary   = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint      = Color(0xFFBDBDBD);
  static const Color success       = Color(0xFF43A047);
  static const Color warning       = Color(0xFFFB8C00);
  static const Color error         = Color(0xFFE53935);
  static const Color info          = Color(0xFF1E88E5);

  static const Map<String, Color> regionColors = {
    'I':   Color(0xFF1565C0),
    'IIa': Color(0xFF2E7D32),
    'IIb': Color(0xFF388E3C),
    'III': Color(0xFFF9A825),
    'IV':  Color(0xFFE65100),
    'V':   Color(0xFFBF360C),
  };
}

class AppTextStyles {
  static const String _fontFamily = 'Poppins';

  static const TextStyle heading1 = TextStyle(
    fontFamily: _fontFamily, fontSize: 24,
    fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const TextStyle heading2 = TextStyle(
    fontFamily: _fontFamily, fontSize: 20,
    fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle heading3 = TextStyle(
    fontFamily: _fontFamily, fontSize: 16,
    fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily, fontSize: 16,
    fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily, fontSize: 14,
    fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily, fontSize: 12,
    fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily, fontSize: 16,
    fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5,
  );
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily, fontSize: 12,
    fontWeight: FontWeight.w500, color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily, fontSize: 11,
    fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins', fontSize: 18,
          fontWeight: FontWeight.w600, color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: AppTextStyles.button,
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTextStyles.label,
        hintStyle:
            AppTextStyles.body.copyWith(color: AppColors.textHint),
      ),
      // FIXED: CardThemeData instead of CardTheme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(0),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class AppConstants {
  static const String appName        = 'AgricAssist ZW';
  static const String appVersion     = '1.0.0';
  static const String appTagline     = 'Smart Farming for Zimbabwe';
  static const int    trialDays      = 14;
  static const double subscriptionGBP = 2.50;
  static const double subscriptionUSD = 3.20;
  static const String userIdPrefix   = 'ZW';
  static const int    userIdLength   = 6;
  static const String apiBaseUrl     = 'http://10.0.2.2:3000/api';
  static const String apiVersion     = 'v1';
  static const String dbName         = 'agric_assist.db';
  static const int    dbVersion      = 1;
  static const String keyUserId      = 'user_id';
  static const String keyAuthToken   = 'auth_token';
  static const String keyIsLoggedIn  = 'is_logged_in';
  static const String keyTrialStart  = 'trial_start_date';
  static const String keyLanguage    = 'app_language';

  static const List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'sn', 'name': 'Shona (ChiShona)'},
    {'code': 'nd', 'name': 'Ndebele (IsiNdebele)'},
  ];
}