// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
import 'screens/auth/forgot_password_screen.dart';
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
import 'providers/ai_provider.dart';
import 'screens/ai/ai_diagnosis_screen.dart';
import 'screens/ai/ai_yield_screen.dart';
import 'screens/ai/ai_chat_screen.dart';
import 'providers/farm_management_provider.dart';
import 'screens/farm_management/farm_registration_screen.dart';
import 'screens/farm_management/worker_onboarding_screen.dart';
import 'screens/farm_management/gps_clockin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── DO NOT init sqflite FFI here ──────────────────────
  // DatabaseService handles platform-aware FFI init internally
  // using path_provider for a stable persistent path.
  // Initialising it here causes a second conflicting databaseFactory
  // assignment that points to the wrong .dart_tool path.

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
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => FarmManagementProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          // ── Public routes (no gate) ──────────────────
          '/':                  (context) => const SplashScreen(),
          '/login':             (context) => const LoginScreen(),
          '/register':          (context) => const RegistrationScreen(),
          '/forgot-password':   (context) => const ForgotPasswordScreen(),
          '/farm-profile':      (context) => const FarmProfileSetupScreen(),
          '/paywall':           (context) => const PaywallScreen(),
          '/payment-success':   (context) => const PaymentSuccessScreen(),

          // ── Core routes — base subscription gate ─────
          '/dashboard':         (context) => const _SubscriptionGate(
                                    child: DashboardScreen()),
          '/crops':             (context) => const _SubscriptionGate(
                                    child: CropManagementScreen()),
          '/livestock':         (context) => const _SubscriptionGate(
                                    child: LivestockScreen()),
          '/weather':           (context) => const _SubscriptionGate(
                                    child: WeatherScreen()),
          '/finances':          (context) => const _SubscriptionGate(
                                    child: FinanceScreen()),
          '/horticulture':      (context) => const _SubscriptionGate(
                                    child: HorticultureScreen()),
          '/knowledge-base':    (context) => const _SubscriptionGate(
                                    child: KnowledgeBaseScreen()),
          '/market':            (context) => const _SubscriptionGate(
                                    child: MarketPricesScreen()),
          '/news':              (context) => const _SubscriptionGate(
                                    child: AgriNewsScreen()),
          '/labour':            (context) => const _SubscriptionGate(
                                    child: LabourTrackerScreen()),
          '/calendar':          (context) => const _SubscriptionGate(
                                    child: FarmCalendarScreen()),
          '/pest-disease':      (context) => const _SubscriptionGate(
                                    child: PestDiseaseScreen()),
          '/soil':              (context) => const _SubscriptionGate(
                                    child: SoilManagementScreen()),
          '/irrigation':        (context) => const _SubscriptionGate(
                                    child: IrrigationScreen()),
          '/input-calculator':  (context) => const _SubscriptionGate(
                                    child: InputCalculatorScreen()),
          '/reports':           (context) => const _SubscriptionGate(
                                    child: ReportsScreen()),
          '/profile':           (context) => const _SubscriptionGate(
                                    child: ProfileScreen()),

          // ── Premium routes — premium gate ────────────
          '/ai-diagnosis':      (context) => const _PremiumGate(
                                    child: AiDiagnosisScreen()),
          '/ai-yield':          (context) => const _PremiumGate(
                                    child: AiYieldScreen()),
          '/ai-chat':           (context) => const _PremiumGate(
                                    child: AiChatScreen()),
          '/farm-registration': (context) => const _PremiumGate(
                                    child: FarmRegistrationScreen()),
          '/worker-onboarding': (context) => const _PremiumGate(
                                    child: WorkerOnboardingScreen()),
          '/gps-clockin':       (context) => const _PremiumGate(
                                    child: GpsClockInScreen()),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      ),
    );
  }
}

// ── Base subscription gate (core 15 modules) ─────────────
// Blocks access if trial expired AND not base-subscribed.
class _SubscriptionGate extends StatelessWidget {
  final Widget child;
  const _SubscriptionGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const LoginScreen();
    if (SubscriptionService.isSoftLocked(user)) {
      return const PaywallScreen();
    }
    return child;
  }
}

// ── Premium gate (AI + advanced modules) ─────────────────
// Blocks access if:
//   - trial expired AND not base-subscribed (show paywall base tab), OR
//   - base-subscribed but premium expired/never subscribed (show paywall premium tab)
class _PremiumGate extends StatelessWidget {
  final Widget child;
  const _PremiumGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const LoginScreen();
    // Check base access first
    if (SubscriptionService.isSoftLocked(user)) {
      return const PaywallScreen();
    }
    // Then check premium access
    if (SubscriptionService.isPremiumLocked(user)) {
      return const PaywallScreen();
    }
    return child;
  }
}