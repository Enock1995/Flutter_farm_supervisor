// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/farm_profile_provider.dart';
import 'providers/crop_provider.dart';
import 'providers/livestock_provider.dart';
import 'providers/finance_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/farm_profile/farm_profile_setup_screen.dart';
import 'screens/crops/crop_management_screen.dart';
import 'screens/livestock/livestock_screen.dart';
import 'screens/weather/weather_screen.dart';
import 'screens/finances/finance_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AgricAssistApp());
}

class AgricAssistApp extends StatelessWidget {
  const AgricAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FarmProfileProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
        ChangeNotifierProvider(create: (_) => LivestockProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/':             (context) => const SplashScreen(),
          '/login':        (context) => const LoginScreen(),
          '/register':     (context) => const RegistrationScreen(),
          '/farm-profile': (context) => const FarmProfileSetupScreen(),
          '/dashboard':    (context) => const DashboardScreen(),
          '/crops':        (context) => const CropManagementScreen(),
          '/livestock':    (context) => const LivestockScreen(),
          '/weather':      (context) => const WeatherScreen(),
          '/finances':     (context) => const FinanceScreen(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      ),
    );
  }
}