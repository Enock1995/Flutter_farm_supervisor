// lib/screens/dashboard/dashboard_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/zimbabwe_districts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_profile_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../services/subscription_service.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context
            .read<FarmProfileProvider>()
            .loadFarmProfile(user.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isOnline =
        context.watch<ConnectivityProvider>().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await context
                  .read<AuthProvider>()
                  .logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  if (!isOnline) ...[
                    _OfflineBanner(),
                    const SizedBox(height: 12),
                  ],

                  _WelcomeCard(user: user),
                  const SizedBox(height: 16),
                  _RegionCard(region: user.agroRegion),
                  const SizedBox(height: 16),
                  _FarmSummaryCard(),
                  const SizedBox(height: 16),

                  if (!user.isSubscribed &&
                      SubscriptionService.isTrialActive(user)) ...[
                    _TrialCard(user: user),
                    const SizedBox(height: 16),
                  ],

                  // ── Core Modules ─────────────────────
                  Text('Your Modules',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  const _ModuleGrid(),
                  const SizedBox(height: 24),

                  // ── Premium sections ─────────────────
                  _PremiumSectionHeader(
                    icon: '🤖',
                    title: 'AI-Powered Features',
                    subtitle: 'Smart diagnosis, prediction & advisory',
                  ),
                  const SizedBox(height: 12),
                  _PremiumModuleGrid(modules: _aiModules),
                  const SizedBox(height: 24),

                  _PremiumSectionHeader(
                    icon: '📊',
                    title: 'Analytics & Reporting',
                    subtitle: 'Advanced insights and automated reports',
                  ),
                  const SizedBox(height: 12),
                  _PremiumModuleGrid(modules: _analyticsModules),
                  const SizedBox(height: 24),

                  _PremiumSectionHeader(
                    icon: '👷',
                    title: 'Remote Farm Management',
                    subtitle: 'Manage workers and farms from anywhere',
                  ),
                  const SizedBox(height: 12),
                  _PremiumModuleGrid(modules: _farmManagementModules),
                  const SizedBox(height: 24),

                  _PremiumSectionHeader(
                    icon: '🌿',
                    title: 'AGRITEX Mudhumeni Network',
                    subtitle: 'Extension officer knowledge network',
                  ),
                  const SizedBox(height: 12),
                  _PremiumModuleGrid(modules: _agritexModules),
                  const SizedBox(height: 24),

                  _PremiumSectionHeader(
                    icon: '🌦️',
                    title: 'Smart Environmental Monitoring',
                    subtitle: 'Hyperlocal alerts and smart irrigation',
                  ),
                  const SizedBox(height: 12),
                  _PremiumModuleGrid(modules: _environmentModules),
                  const SizedBox(height: 24),

                  _PremiumSectionHeader(
                    icon: '💰',
                    title: 'Financial Tools',
                    subtitle: 'Cost tracking, loans and market analysis',
                  ),
                  const SizedBox(height: 12),
                  _PremiumModuleGrid(modules: _financialModules),
                  const SizedBox(height: 24),

                  _PremiumSectionHeader(
                    icon: '🗺️',
                    title: 'Field & Inventory Management',
                    subtitle: 'GPS mapping, stock and livestock health',
                  ),
                  const SizedBox(height: 12),
                  _PremiumModuleGrid(modules: _fieldModules),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

// ── Premium module data ───────────────────────────────────

final _aiModules = [
  _Module(
    icon: Icons.medical_services_outlined,
    label: 'AI Crop &\nLivestock Diagnosis',
    color: const Color(0xFF7B2D8B),
    route: '/ai-diagnosis',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.trending_up,
    label: 'AI Yield\nPrediction',
    color: const Color(0xFF7B2D8B),
    route: '/ai-yield',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.smart_toy_outlined,
    label: 'AI Farm\nAdvisory Chat',
    color: const Color(0xFF7B2D8B),
    route: '/ai-chat',
    isBuilt: true,
  ),
];

final _analyticsModules = [
  _Module(
    icon: Icons.bar_chart_outlined,
    label: 'Advanced\nAnalytics',
    color: const Color(0xFF1565C0),
    route: '/analytics',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.summarize_outlined,
    label: 'Auto PDF/Excel\nReports',
    color: const Color(0xFF1565C0),
    route: '/auto-reports',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.corporate_fare_outlined,
    label: 'Multi-Farm\nManagement',
    color: const Color(0xFF1565C0),
    route: '/multi-farm',
    isBuilt: true,
  ),
];

final _farmManagementModules = [
  _Module(
    icon: Icons.add_location_alt_outlined,
    label: 'Farm\nRegistration',
    color: const Color(0xFF2E7D32),
    route: '/farm-registration',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.group_add_outlined,
    label: 'Worker\nOnboarding',
    color: const Color(0xFF2E7D32),
    route: '/worker-onboarding',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.location_on_outlined,
    label: 'GPS\nClock-In/Out',
    color: const Color(0xFF2E7D32),
    route: '/gps-clockin',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.assignment_outlined,
    label: 'Remote Task\nAssignment',
    color: const Color(0xFF2E7D32),
    route: '/task-assignment',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.dynamic_feed_outlined,
    label: 'Farm Activity\nFeed',
    color: const Color(0xFF2E7D32),
    route: '/activity-feed',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.payments_outlined,
    label: 'Payroll &\nEcoCash Payout',
    color: const Color(0xFF2E7D32),
    route: '/payroll',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.leaderboard_outlined,
    label: 'Worker\nPerformance',
    color: const Color(0xFF2E7D32),
    route: '/worker-performance',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.edit_note_outlined,
    label: 'Daily Field\nReports',
    color: const Color(0xFF2E7D32),
    route: '/field-reports',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.photo_library_outlined,
    label: 'Farm\nPhoto Diary',
    color: const Color(0xFF2E7D32),
    route: '/photo-diary',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.sos_outlined,
    label: 'Emergency\nSOS Alert',
    color: const Color(0xFFC62828),
    route: '/sos-alert',
    isBuilt: true,
  ),
];

final _agritexModules = [
  _Module(
    icon: Icons.verified_user_outlined,
    label: 'Mudhumeni\nRegistration',
    color: const Color(0xFF558B2F),
    route: '/mudhumeni-registration',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.map_outlined,
    label: 'Area & Farmer\nManagement',
    color: const Color(0xFF558B2F),
    route: '/area-management',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.campaign_outlined,
    label: 'Knowledge\nPosts & Alerts',
    color: const Color(0xFF558B2F),
    route: '/knowledge-posts',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.forum_outlined,
    label: 'Public\nQ&A',
    color: const Color(0xFF558B2F),
    route: '/public-qa',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.lock_outline,
    label: 'Private\nQ&A',
    color: const Color(0xFF558B2F),
    route: '/private-qa',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.groups_outlined,
    label: 'Farmer\nCommunity',
    color: const Color(0xFF558B2F),
    route: '/community',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.event_available_outlined,
    label: 'Field Visit\nScheduler',
    color: const Color(0xFF558B2F),
    route: '/field-visits',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.calendar_today_outlined,
    label: 'Seasonal\nCrop Calendar',
    color: const Color(0xFF558B2F),
    route: '/seasonal-calendar',
    isBuilt: true,
  ),
  _Module(
    icon: Icons.bubble_chart_outlined,
    label: 'Problem\nHeatmap',
    color: const Color(0xFF558B2F),
    route: '/problem-heatmap',
    isBuilt: true,
  ),
];

final _environmentModules = [
  _Module(
    icon: Icons.notifications_active_outlined,
    label: 'Hyperlocal\nWeather Alerts',
    color: const Color(0xFF0277BD),
    route: '/weather-alerts',
    isBuilt: false,
  ),
  _Module(
    icon: Icons.schedule_outlined,
    label: 'Irrigation\nScheduling',
    color: const Color(0xFF0277BD),
    route: '/irrigation-scheduling',
    isBuilt: false,
  ),
];

final _financialModules = [
  _Module(
    icon: Icons.price_change_outlined,
    label: 'Input Cost vs\nMarket Price',
    color: const Color(0xFFE65100),
    route: '/cost-market',
    isBuilt: false,
  ),
  _Module(
    icon: Icons.account_balance_outlined,
    label: 'Loan & Credit\nManager',
    color: const Color(0xFFE65100),
    route: '/loan-manager',
    isBuilt: false,
  ),
];

final _fieldModules = [
  _Module(
    icon: Icons.satellite_alt_outlined,
    label: 'GPS Field\nMapping',
    color: const Color(0xFF4E342E),
    route: '/gps-mapping',
    isBuilt: false,
  ),
  _Module(
    icon: Icons.inventory_2_outlined,
    label: 'Input Inventory\nTracker',
    color: const Color(0xFF4E342E),
    route: '/inventory',
    isBuilt: false,
  ),
  _Module(
    icon: Icons.vaccines_outlined,
    label: 'Livestock Health\nRecords',
    color: const Color(0xFF4E342E),
    route: '/livestock-health',
    isBuilt: false,
  ),
];

// ── Module data class ─────────────────────────────────────
class _Module {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final bool isBuilt;
  const _Module({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    this.isBuilt = false,
  });
}

// ── Offline banner ────────────────────────────────────────
class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You are offline. All data saved locally '
              '— reconnect for live weather and market prices.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Welcome card ──────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final dynamic user;
  const _WelcomeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.heading2
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mhoro! 👋',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white70)),
                  Text(user.fullName,
                      style: AppTextStyles.heading3
                          .copyWith(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    '${user.userId}  •  ${user.district}',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

// ── Region card ───────────────────────────────────────────
class _RegionCard extends StatelessWidget {
  final String region;
  const _RegionCard({required this.region});

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.regionColors[region] ?? AppColors.primary;
    final description =
        ZimbabweDistricts.regionDescriptions[region] ?? '';
    final crops =
        ZimbabweDistricts.regionCrops[region] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Region $region',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Text('Your Agro-Ecological Zone',
                  style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(
            'Recommended: ${crops.take(4).join(', ')}',
            style: AppTextStyles.body.copyWith(
                color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Farm summary card ─────────────────────────────────────
class _FarmSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FarmProfileProvider>(
      builder: (context, provider, _) {
        final profile = provider.farmProfile;
        if (profile == null) {
          return GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, '/farm-profile'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.agriculture,
                      color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Set up your farm profile for personalised advice.',
                      style: AppTextStyles.body,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.accent),
                ],
              ),
            ),
          );
        }
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ProfileScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Farm',
                        style: AppTextStyles.heading3),
                    Text('View profile →',
                        style: AppTextStyles.bodySmall
                            .copyWith(
                                color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FarmStat(
                        icon: Icons.straighten,
                        label: 'Size',
                        value:
                            '${profile.farmSizeHectares} ha'),
                    const SizedBox(width: 12),
                    _FarmStat(
                        icon: Icons.eco,
                        label: 'Crops',
                        value:
                            '${profile.crops.length} types'),
                    const SizedBox(width: 12),
                    _FarmStat(
                        icon: Icons.pets,
                        label: 'Livestock',
                        value:
                            '${profile.livestock.length} types'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FarmStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _FarmStat(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ── Trial card ────────────────────────────────────────────
class _TrialCard extends StatelessWidget {
  final dynamic user;
  const _TrialCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final daysLeft =
        SubscriptionService.trialDaysRemaining(user);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time,
              color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$daysLeft days left in your free trial. '
              'Upgrade for lifetime access — just \$2.99.',
              style: AppTextStyles.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/paywall'),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

// ── Premium section header ────────────────────────────────
class _PremiumSectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  const _PremiumSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: AppTextStyles.heading3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B2D8B)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFF7B2D8B)
                              .withOpacity(0.3)),
                    ),
                    child: const Text('👑 Premium',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7B2D8B))),
                  ),
                ],
              ),
              Text(subtitle,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Core module grid ──────────────────────────────────────
class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid();

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'icon': Icons.eco,
        'label': 'Crop\nManagement',
        'color': AppColors.primary,
        'route': '/crops',
        'ready': true,
      },
      {
        'icon': Icons.pets,
        'label': 'Livestock',
        'color': AppColors.earth,
        'route': '/livestock',
        'ready': true,
      },
      {
        'icon': Icons.local_florist_outlined,
        'label': 'Horticulture',
        'color': AppColors.primaryLight,
        'route': '/horticulture',
        'ready': true,
      },
      {
        'icon': Icons.wb_sunny_outlined,
        'label': 'Weather',
        'color': AppColors.accent,
        'route': '/weather',
        'ready': true,
      },
      {
        'icon': Icons.storefront_outlined,
        'label': 'Market\nPrices',
        'color': AppColors.earth,
        'route': '/market',
        'ready': true,
      },
      {
        'icon': Icons.newspaper_outlined,
        'label': 'Agri News',
        'color': AppColors.info,
        'route': '/news',
        'ready': true,
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Finances',
        'color': AppColors.info,
        'route': '/finances',
        'ready': true,
      },
      {
        'icon': Icons.calendar_month_outlined,
        'label': 'Farm\nCalendar',
        'color': AppColors.primaryDark,
        'route': '/calendar',
        'ready': true,
      },
      {
        'icon': Icons.people_outline,
        'label': 'Labour\nTracker',
        'color': AppColors.earthLight,
        'route': '/labour',
        'ready': true,
      },
      {
        'icon': Icons.bug_report_outlined,
        'label': 'Pest &\nDisease',
        'color': AppColors.error,
        'route': '/pest-disease',
        'ready': true,
      },
      {
        'icon': Icons.water_drop_outlined,
        'label': 'Irrigation\nManager',
        'color': AppColors.info,
        'route': '/irrigation',
        'ready': true,
      },
      {
        'icon': Icons.layers_outlined,
        'label': 'Soil\nManagement',
        'color': AppColors.earth,
        'route': '/soil',
        'ready': true,
      },
      {
        'icon': Icons.calculate_outlined,
        'label': 'Input\nCalculator',
        'color': AppColors.success,
        'route': '/input-calculator',
        'ready': true,
      },
      {
        'icon': Icons.picture_as_pdf_outlined,
        'label': 'Reports\n& Export',
        'color': AppColors.primaryLight,
        'route': '/reports',
        'ready': true,
      },
      {
        'icon': Icons.menu_book_outlined,
        'label': 'Knowledge\nBase',
        'color': AppColors.earthLight,
        'route': '/knowledge-base',
        'ready': true,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final m = modules[index];
        final color = m['color'] as Color;
        final route = m['route'] as String;
        final isReady = m['ready'] as bool;

        return GestureDetector(
          onTap: () {
            if (isReady) {
              Navigator.pushNamed(context, route);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${(m['label'] as String).replaceAll('\n', ' ')} — coming soon!',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(m['icon'] as IconData,
                        color: color, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m['label'] as String,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Premium module grid ───────────────────────────────────
class _PremiumModuleGrid extends StatelessWidget {
  final List<_Module> modules;
  const _PremiumModuleGrid({required this.modules});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final m = modules[index];

        return GestureDetector(
          onTap: () {
            if (m.isBuilt) {
              Navigator.pushNamed(context, m.route);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${m.label.replaceAll('\n', ' ')} — coming soon!',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: m.isBuilt ? Colors.white : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: m.color.withOpacity(m.isBuilt ? 0.4 : 0.2),
                width: m.isBuilt ? 1.5 : 1,
              ),
              boxShadow: m.isBuilt
                  ? [
                      BoxShadow(
                        color: m.color.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: m.color.withOpacity(
                              m.isBuilt ? 0.12 : 0.07),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(m.icon,
                            color: m.color.withOpacity(
                                m.isBuilt ? 1.0 : 0.45),
                            size: 26),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption
                            .copyWith(
                          color: m.isBuilt
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          fontWeight: m.isBuilt
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: m.isBuilt
                          ? AppColors.success.withOpacity(0.12)
                          : const Color(0xFF7B2D8B)
                              .withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                    child: Text(
                      m.isBuilt ? '✅' : '👑',
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}