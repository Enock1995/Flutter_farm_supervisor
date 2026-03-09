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
                  // Connectivity banner
                  if (!isOnline) ...[
                    _OfflineBanner(),
                    const SizedBox(height: 12),
                  ],

                  _WelcomeCard(user: user),
                  const SizedBox(height: 16),
                  _RegionCard(
                      region: user.agroRegion),
                  const SizedBox(height: 16),
                  _FarmSummaryCard(),
                  const SizedBox(height: 16),

                  // Trial banner — only if not subscribed
                  // and trial not yet expired
                  if (!user.isSubscribed &&
                      SubscriptionService
                          .isTrialActive(user)) ...[
                    _TrialCard(user: user),
                    const SizedBox(height: 16),
                  ],

                  Text('Your Modules',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  const _ModuleGrid(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
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
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.warning),
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
            colors: [
              AppColors.primaryDark,
              AppColors.primary
            ],
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text('Mhoro! 👋',
                      style: AppTextStyles.bodySmall
                          .copyWith(
                              color: Colors.white70)),
                  Text(user.fullName,
                      style: AppTextStyles.heading3
                          .copyWith(
                              color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    '${user.userId}  •  ${user.district}',
                    style: AppTextStyles.caption
                        .copyWith(
                            color: Colors.white60),
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
        border: Border.all(
            color: color.withOpacity(0.3)),
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
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Text('Region $region',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Text('Your Agro-Ecological Zone',
                  style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          Text(description,
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(
            'Recommended: ${crops.take(4).join(', ')}',
            style: AppTextStyles.body.copyWith(
                color: color,
                fontWeight: FontWeight.w500),
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
            onTap: () => Navigator.pushNamed(
                context, '/farm-profile'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent
                    .withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent
                        .withOpacity(0.3)),
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
                builder: (_) =>
                    const ProfileScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Farm',
                        style:
                            AppTextStyles.heading3),
                    Text('View profile →',
                        style:
                            AppTextStyles.bodySmall
                                .copyWith(
                                    color: AppColors
                                        .primary)),
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
            Icon(icon,
                color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            Text(label,
                style: AppTextStyles.caption),
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

// ── Module grid ───────────────────────────────────────────
class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid();

  @override
  Widget build(BuildContext context) {
    // ready: true  = built and navigable
    // ready: false = coming soon (shows snackbar + "soon" badge)
    final modules = [
      // ── Row 1: Core farm management ──────────────
      {
        'icon':  Icons.eco,
        'label': 'Crop\nManagement',
        'color': AppColors.primary,
        'route': '/crops',
        'ready': true,
      },
      {
        'icon':  Icons.pets,
        'label': 'Livestock',
        'color': AppColors.earth,
        'route': '/livestock',
        'ready': true,
      },
      {
        'icon':  Icons.local_florist_outlined,
        'label': 'Horticulture',
        'color': AppColors.primaryLight,
        'route': '/horticulture',
        'ready': true,
      },

      // ── Row 2: Intelligence & market ─────────────
      {
        'icon':  Icons.wb_sunny_outlined,
        'label': 'Weather',
        'color': AppColors.accent,
        'route': '/weather',
        'ready': true,
      },
      {
        'icon':  Icons.storefront_outlined,
        'label': 'Market\nPrices',
        'color': AppColors.earth,
        'route': '/market',
        'ready': true,
      },
      {
        'icon':  Icons.newspaper_outlined,
        'label': 'Agri News',
        'color': AppColors.info,
        'route': '/news',
        'ready': true,
      },

      // ── Row 3: Farm operations ────────────────────
      {
        'icon':  Icons.account_balance_wallet_outlined,
        'label': 'Finances',
        'color': AppColors.info,
        'route': '/finances',
        'ready': true,
      },
      {
        'icon':  Icons.calendar_month_outlined,
        'label': 'Farm\nCalendar',
        'color': AppColors.primaryDark,
        'route': '/calendar',
        'ready': true,
      },
      {
        'icon':  Icons.people_outline,
        'label': 'Labour\nTracker',
        'color': AppColors.earthLight,
        'route': '/labour',
        'ready': true,
      },

      // ── Row 4: Advisory tools ─────────────────────
      {
        'icon':  Icons.bug_report_outlined,
        'label': 'Pest &\nDisease',
        'color': AppColors.error,
        'route': '/pest-disease',
        'ready': true,
      },
      {
        'icon':  Icons.water_drop_outlined,
        'label': 'Irrigation\nManager',
        'color': AppColors.info,
        'route': '/irrigation',
        'ready': true,
      },
      {
        'icon':  Icons.layers_outlined,
        'label': 'Soil\nManagement',
        'color': AppColors.earth,
        'route': '/soil',
        'ready': true,
      },

      // ── Row 5: Productivity ───────────────────────
      {
        'icon':  Icons.calculate_outlined,
        'label': 'Input\nCalculator',
        'color': AppColors.success,
        'route': '/input-calculator',
        'ready': true,
      },
      {
        'icon':  Icons.picture_as_pdf_outlined,
        'label': 'Reports\n& Export',
        'color': AppColors.primaryLight,
        'route': '/reports',
        'ready': true,
      },
      {
        'icon':  Icons.menu_book_outlined,
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
        final m       = modules[index];
        final color   = m['color'] as Color;
        final route   = m['route'] as String;
        final isReady = m['ready'] as bool;

        return GestureDetector(
          onTap: () {
            if (isReady) {
              Navigator.pushNamed(context, route);
            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(
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
              color: isReady
                  ? Colors.white
                  : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isReady
                  ? const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
              border: isReady
                  ? null
                  : Border.all(
                      color: AppColors.divider,
                      width: 1,
                    ),
            ),
            child: Stack(
              children: [
                // Module content
                Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isReady
                              ? color.withOpacity(0.12)
                              : color.withOpacity(0.06),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(
                          m['icon'] as IconData,
                          color: isReady
                              ? color
                              : color.withOpacity(0.35),
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        m['label'] as String,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption
                            .copyWith(
                          color: isReady
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          fontWeight: isReady
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // "soon" badge — top-right on unbuilt modules
                if (!isReady)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textHint
                            .withOpacity(0.14),
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                      child: Text(
                        'soon',
                        style: AppTextStyles.caption
                            .copyWith(
                          fontSize: 9,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w600,
                        ),
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