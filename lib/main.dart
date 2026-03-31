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
import 'providers/payroll_fieldreport_provider.dart';
import 'screens/farm_management/farm_registration_screen.dart';
import 'screens/farm_management/worker_onboarding_screen.dart';
import 'screens/farm_management/gps_clockin_screen.dart';
import 'screens/farm_management/task_assignment_screen.dart';
import 'screens/farm_management/activity_feed_screen.dart';
import 'screens/farm_management/payroll_screen.dart';
import 'screens/farm_management/field_reports_screen.dart';
import 'screens/farm_management/photo_diary_screen.dart';
import 'providers/sos_provider.dart';
import 'screens/farm_management/sos_alert_screen.dart';
import 'screens/farm_management/worker_performance_screen.dart';
import 'screens/analytics/advanced_analytics_screen.dart';
import 'screens/analytics/auto_reports_screen.dart';
import 'screens/farm_management/multi_farm_screen.dart';
// ── Mudhumeni imports ────────────────────────────────────
import 'screens/mudhumeni/mudhumeni_registration_screen.dart';
import 'screens/mudhumeni/knowledge_posts_screen.dart';
import 'screens/mudhumeni/qa_screens.dart';
import 'screens/mudhumeni/community_fieldvisits_screens.dart';
import 'screens/mudhumeni/problem_heatmap_screen.dart';
import 'screens/mudhumeni/area_management_screen.dart';
// ── Vet imports ──────────────────────────────────────────
import 'screens/vet/vet_registration_screen.dart';
import 'screens/vet/farmer_vet_network_screen.dart';
import 'screens/vet/vet_dashboard_screen.dart';
import 'screens/vet/vet_knowledge_posts_screen.dart';
import 'screens/vet/vet_qa_screens.dart';
// ── Admin ────────────────────────────────────────────────
import 'screens/admin/admin_panel_screen.dart';
import 'screens/debug/debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        ChangeNotifierProvider(create: (_) => PayrollFieldReportProvider()),
        ChangeNotifierProvider(create: (_) => SosProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          // ── Public ───────────────────────────────────
          '/':                 (context) => const SplashScreen(),
          '/login':            (context) => const LoginScreen(),
          '/register':         (context) => const RegistrationScreen(),
          '/forgot-password':  (context) => const ForgotPasswordScreen(),
          '/farm-profile':     (context) => const FarmProfileSetupScreen(),
          '/paywall':          (context) => const PaywallScreen(),
          '/payment-success':  (context) => const PaymentSuccessScreen(),

          // ── Core (base subscription gate) ────────────
          '/dashboard':        (context) => const _SubscriptionGate(child: DashboardScreen()),
          '/crops':            (context) => const _SubscriptionGate(child: CropManagementScreen()),
          '/livestock':        (context) => const _SubscriptionGate(child: LivestockScreen()),
          '/weather':          (context) => const _SubscriptionGate(child: WeatherScreen()),
          '/finances':         (context) => const _SubscriptionGate(child: FinanceScreen()),
          '/horticulture':     (context) => const _SubscriptionGate(child: HorticultureScreen()),
          '/knowledge-base':   (context) => const _SubscriptionGate(child: KnowledgeBaseScreen()),
          '/market':           (context) => const _SubscriptionGate(child: MarketPricesScreen()),
          '/news':             (context) => const _SubscriptionGate(child: AgriNewsScreen()),
          '/labour':           (context) => const _SubscriptionGate(child: LabourTrackerScreen()),
          '/calendar':         (context) => const _SubscriptionGate(child: FarmCalendarScreen()),
          '/pest-disease':     (context) => const _SubscriptionGate(child: PestDiseaseScreen()),
          '/soil':             (context) => const _SubscriptionGate(child: SoilManagementScreen()),
          '/irrigation':       (context) => const _SubscriptionGate(child: IrrigationScreen()),
          '/input-calculator': (context) => const _SubscriptionGate(child: InputCalculatorScreen()),
          '/reports':          (context) => const _SubscriptionGate(child: ReportsScreen()),
          '/profile':          (context) => const _SubscriptionGate(child: ProfileScreen()),

          // ── Premium (AI + advanced) ───────────────────
          '/ai-diagnosis':     (context) => const _PremiumGate(child: AiDiagnosisScreen()),
          '/ai-yield':         (context) => const _PremiumGate(child: AiYieldScreen()),
          '/ai-chat':          (context) => const _PremiumGate(child: AiChatScreen()),

          // Remote Farm Management
          '/farm-registration':  (context) => const _PremiumGate(child: FarmRegistrationScreen()),
          '/worker-onboarding':  (context) => const _PremiumGate(child: WorkerOnboardingScreen()),
          '/gps-clockin':        (context) => const _PremiumGate(child: GpsClockInScreen()),
          '/task-assignment':    (context) => const _PremiumGate(child: TaskAssignmentScreen()),
          '/activity-feed':      (context) => const _PremiumGate(child: ActivityFeedScreen()),
          '/payroll':            (context) => const _PremiumGate(child: PayrollScreen()),
          '/field-reports':      (context) => const _PremiumGate(child: FieldReportsScreen()),
          '/photo-diary':        (context) => const _PremiumGate(child: PhotoDiaryScreen()),
          '/sos-alert':          (context) => _PremiumGate(child: SosAlertScreen()),
          '/worker-performance': (context) => _PremiumGate(child: WorkerPerformanceScreen()),
          '/analytics':          (context) => _PremiumGate(child: AdvancedAnalyticsScreen()),
          '/auto-reports':       (context) => _PremiumGate(child: AutoReportsScreen()),
          '/multi-farm':         (context) => _PremiumGate(child: MultiFarmScreen()),

          // ── AGRITEX Mudhumeni Network ─────────────────
          '/mudhumeni-registration': (context) => const _PremiumGate(child: MudhumeniRegistrationScreen()),
          '/area-management':        (context) => const _PremiumGate(child: _AuthorityGate(child: AreaManagementScreen())),
          '/knowledge-posts':        (context) => const _PremiumGate(child: KnowledgePostsScreen()),
          '/public-qa':              (context) => const _PremiumGate(child: PublicQaScreen()),
          '/private-qa':             (context) => const _PremiumGate(child: PrivateQaScreen()),
          '/community':              (context) => const _PremiumGate(child: CommunityScreen()),
          '/field-visits':           (context) => const _PremiumGate(child: FieldVisitsScreen()),
          '/seasonal-calendar':      (context) => const _PremiumGate(child: SeasonalCalendarScreen()),
          '/problem-heatmap':        (context) => const _PremiumGate(child: ProblemHeatmapScreen()),

          // ── Veterinary Services ───────────────────────
          '/vet-registration':      (context) => const _PremiumGate(child: VetRegistrationScreen()),
          '/vet-network':           (context) => const _PremiumGate(child: FarmerVetNetworkScreen()),
          '/vet-dashboard':         (context) => const _PremiumGate(child: VetDashboardScreen()),
          '/vet-knowledge':         (context) => const _PremiumGate(child: VetKnowledgePostsScreen()),
          '/vet-qa':                (context) => const _PremiumGate(child: VetQaScreens()),

          // ── Admin panel (hierarchy-aware) ─────────────
          '/admin-panel':            (context) => _AdminGate(child: AdminPanelScreen()),
          '/debug':                  (context) => const DebugScreen(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      ),
    );
  }
}

// =============================================================================
// GATES
// =============================================================================

// ── Subscription gate ─────────────────────────────────────
class _SubscriptionGate extends StatelessWidget {
  final Widget child;
  const _SubscriptionGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const LoginScreen();
    if (SubscriptionService.isSoftLocked(user)) return const PaywallScreen();
    return child;
  }
}

// ── Premium gate — all admin levels bypass ────────────────
class _PremiumGate extends StatelessWidget {
  final Widget child;
  const _PremiumGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const LoginScreen();
    if (SubscriptionService.isSoftLocked(user)) return const PaywallScreen();
    // All authority levels (district, provincial, national) bypass premium gate
    if (auth.isAdmin) return child;
    if (SubscriptionService.isPremiumLocked(user)) return const PaywallScreen();
    return child;
  }
}

// ── Mudhumeni gate — mudhumeni or any admin ───────────────
class _MudhumeniGate extends StatelessWidget {
  final Widget child;
  const _MudhumeniGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isMudhumeni || auth.isAdmin) return child;
    return _accessDenied(
      context,
      title: 'Mudhumeni Access Only',
      message:
          'This section is reserved for verified AGRITEX Mudhumeni '
          'extension officers. Register as a Mudhumeni to request access.',
      actionLabel: 'Register as Mudhumeni',
      actionRoute: '/mudhumeni-registration',
      color: const Color(0xFF558B2F),
    );
  }
}

// ── Authority gate — mudhumeni or any admin (for area management) ─
class _AuthorityGate extends StatelessWidget {
  final Widget child;
  const _AuthorityGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAnyAuthority) return child;
    return _accessDenied(
      context,
      title: 'Authority Access Only',
      message:
          'This section is for verified Mudhumeni officers and AGRITEX '
          'administrators. Register as a Mudhumeni to request access.',
      actionLabel: 'Register as Mudhumeni',
      actionRoute: '/mudhumeni-registration',
      color: const Color(0xFF558B2F),
    );
  }
}

// ── Admin gate — district, provincial or national admin ───
class _AdminGate extends StatelessWidget {
  final Widget child;
  const _AdminGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAdmin) return child;
    return _accessDenied(
      context,
      title: 'Admin Access Required',
      message: 'This section is restricted to AGRITEX administrators.',
      color: AppColors.primaryDark,
    );
  }
}

// ── Shared access denied widget ───────────────────────────
Widget _accessDenied(
  BuildContext context, {
  required String title,
  required String message,
  Color color = AppColors.primaryDark,
  String? actionLabel,
  String? actionRoute,
}) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: color,
      foregroundColor: Colors.white,
      title: const Text('Access Restricted'),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: color),
            const SizedBox(height: 16),
            Text(title,
                style: AppTextStyles.heading2
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            if (actionLabel != null && actionRoute != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white),
                onPressed: () =>
                    Navigator.pushNamed(context, actionRoute),
                icon: const Icon(Icons.app_registration),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

// =============================================================================
// ROLE NOTIFICATION OVERLAY
// Wrap DashboardScreen with this to show notification dialogs on login
// =============================================================================
class RoleNotificationOverlay extends StatefulWidget {
  final Widget child;
  const RoleNotificationOverlay({required this.child, super.key});

  @override
  State<RoleNotificationOverlay> createState() =>
      _RoleNotificationOverlayState();
}

class _RoleNotificationOverlayState
    extends State<RoleNotificationOverlay> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (_checked) return;
    _checked = true;
    final auth = context.read<AuthProvider>();
    if (!auth.hasNotifications) return;

    for (final n in auth.pendingNotifications) {
      if (!mounted) break;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              const Text('🔔 '),
              Expanded(
                  child: Text(n.title,
                      style: AppTextStyles.heading3)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.message, style: AppTextStyles.body),
              if (n.reason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reason given:',
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning)),
                      const SizedBox(height: 4),
                      Text(n.reason,
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'From: ${n.fromName} (${n.fromRole.replaceAll('_', ' ')})',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textHint),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK, I understand'),
            ),
          ],
        ),
      );
    }

    await auth.markNotificationsRead();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}