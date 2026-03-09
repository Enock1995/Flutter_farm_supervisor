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
import 'providers/horticulture_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/market_price_provider.dart';
import 'providers/agri_news_provider.dart';
import 'providers/labour_provider.dart';
import 'providers/farm_calendar_provider.dart';
import 'services/subscription_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/farm_profile/farm_profile_setup_screen.dart';
import 'screens/crops/crop_management_screen.dart';
import 'screens/livestock/livestock_screen.dart';
import 'screens/weather/weather_screen.dart';
import 'screens/finances/finance_screen.dart';
import 'screens/horticulture/horticulture_screen.dart';
import 'screens/knowledge_base/knowledge_base_screen.dart';
import 'screens/paywall/paywall_screen.dart';
import 'screens/paywall/payment_success_screen.dart';
import 'screens/market/market_prices_screen.dart';
import 'screens/news/agri_news_screen.dart';
import 'screens/labour/labour_tracker_screen.dart';
import 'screens/calendar/farm_calendar_screen.dart';
import 'providers/pest_disease_provider.dart';
import 'screens/pest_disease/pest_disease_screen.dart';
import 'providers/soil_provider.dart';
import 'screens/soil/soil_management_screen.dart';
import 'providers/irrigation_provider.dart';
import 'screens/irrigation/irrigation_screen.dart';
import 'providers/input_calculator_provider.dart';
import 'screens/input_calculator/input_calculator_screen.dart';
import 'providers/reports_provider.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/profile/profile_screen.dart';


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
        ChangeNotifierProvider(create: (_) => HorticultureProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => MarketPriceProvider()),
        ChangeNotifierProvider(create: (_) => AgriNewsProvider()),
        ChangeNotifierProvider(create: (_) => LabourProvider()),
        ChangeNotifierProvider(create: (_) => FarmCalendarProvider()),
        ChangeNotifierProvider(create: (_) => PestDiseaseProvider()),
        ChangeNotifierProvider(create: (_) => SoilProvider()),
        ChangeNotifierProvider(create: (_) => IrrigationProvider()),
        ChangeNotifierProvider(create: (_) => InputCalculatorProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/':                (context) => const SplashScreen(),
          '/login':           (context) => const LoginScreen(),
          '/register':        (context) => const RegistrationScreen(),
          '/farm-profile':    (context) => const FarmProfileSetupScreen(),
          '/dashboard':       (context) => const _SubscriptionGate(
                                  child: DashboardScreen()),
          '/crops':           (context) => const _SubscriptionGate(
                                  child: CropManagementScreen()),
          '/livestock':       (context) => const _SubscriptionGate(
                                  child: LivestockScreen()),
          '/weather':         (context) => const _SubscriptionGate(
                                  child: WeatherScreen()),
          '/finances':        (context) => const _SubscriptionGate(
                                  child: FinanceScreen()),
          '/horticulture':    (context) => const _SubscriptionGate(
                                  child: HorticultureScreen()),
          '/knowledge-base':  (context) => const _SubscriptionGate(
                                  child: KnowledgeBaseScreen()),
          '/market':          (context) => const _SubscriptionGate(
                                  child: MarketPricesScreen()),
          '/news':            (context) => const _SubscriptionGate(
                                  child: AgriNewsScreen()),
          '/labour':          (context) => const _SubscriptionGate(
                                  child: LabourTrackerScreen()),
          '/calendar':        (context) => const _SubscriptionGate(
                                  child: FarmCalendarScreen()),
          '/paywall':         (context) => const PaywallScreen(),
          '/payment-success': (context) => const PaymentSuccessScreen(),
          '/pest-disease': (context) => const _SubscriptionGate(
    child: PestDiseaseScreen()),
    '/soil': (context) => const _SubscriptionGate(child: SoilManagementScreen()),
    '/irrigation': (context) => const _SubscriptionGate(child: IrrigationScreen()),
    '/input-calculator': (context) => const _SubscriptionGate(
    child: InputCalculatorScreen()),
    '/reports': (context) => const _SubscriptionGate(child: ReportsScreen()),
    '/profile': (context) => const _SubscriptionGate(child: ProfileScreen()),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      ),
    );
  }
}

// ── Subscription Gate ─────────────────────────────────────
// Wraps every protected screen. If user is soft-locked,
// shows PaywallScreen instead of the actual screen.
class _SubscriptionGate extends StatelessWidget {
  final Widget child;
  const _SubscriptionGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    // Not logged in — shouldn't happen but safe fallback
    if (user == null) {
      return const LoginScreen();
    }

    // Soft lock: trial expired + not subscribed
    if (SubscriptionService.isSoftLocked(user)) {
      return const PaywallScreen();
    }

    return child;
  }
}