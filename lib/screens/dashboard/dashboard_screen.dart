// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/zimbabwe_districts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farm_profile_provider.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load farm profile when dashboard opens
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          // Profile button
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProfileScreen()),
            ),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WelcomeCard(user: user),
                  const SizedBox(height: 16),
                  _RegionCard(region: user.agroRegion),
                  const SizedBox(height: 16),
                  _FarmSummaryCard(),
                  const SizedBox(height: 16),
                  if (!user.isSubscribed) _TrialCard(user: user),
                  if (!user.isSubscribed) const SizedBox(height: 16),
                  Text('Your Modules',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  const _ModuleGrid(),
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// WELCOME CARD
// ---------------------------------------------------------------------------
class _WelcomeCard extends StatelessWidget {
  final dynamic user;
  const _WelcomeCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
            // Avatar
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

// ---------------------------------------------------------------------------
// REGION CARD
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// FARM SUMMARY CARD
// ---------------------------------------------------------------------------
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
                      'Set up your farm profile to get personalized advice.',
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
                      value: '${profile.farmSizeHectares} ha',
                    ),
                    const SizedBox(width: 12),
                    _FarmStat(
                      icon: Icons.eco,
                      label: 'Crops',
                      value: '${profile.crops.length} types',
                    ),
                    const SizedBox(width: 12),
                    _FarmStat(
                      icon: Icons.pets,
                      label: 'Livestock',
                      value:
                          '${profile.livestock.length} types',
                    ),
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

// ---------------------------------------------------------------------------
// TRIAL CARD
// ---------------------------------------------------------------------------
class _TrialCard extends StatelessWidget {
  final dynamic user;
  const _TrialCard({required this.user});

  @override
  Widget build(BuildContext context) {
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
              '${user.trialDaysRemaining} days left in your free trial. '
              'Upgrade for lifetime access — just £2.50.',
              style: AppTextStyles.bodySmall,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MODULE GRID
// ---------------------------------------------------------------------------
class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid();

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'icon': Icons.eco,
        'label': 'Crop\nManagement',
        'color': AppColors.primary
      },
      {
        'icon': Icons.pets,
        'label': 'Livestock',
        'color': AppColors.earth
      },
      {
        'icon': Icons.wb_sunny_outlined,
        'label': 'Weather',
        'color': AppColors.accent
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Finances',
        'color': AppColors.info
      },
      {
        'icon': Icons.local_florist_outlined,
        'label': 'Horticulture',
        'color': AppColors.primaryLight
      },
      {
        'icon': Icons.menu_book_outlined,
        'label': 'Knowledge\nBase',
        'color': AppColors.earthLight
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
        return GestureDetector(
         onTap: () {
  if (index == 0) {
    Navigator.pushNamed(context, '/crops');
  } else if (index == 1) {
    Navigator.pushNamed(context, '/livestock');
  } else if (index == 2) {
    Navigator.pushNamed(context, '/weather');
  } else if (index == 3) {
    Navigator.pushNamed(context, '/finances');
  } else if (index == 4) {
    Navigator.pushNamed(context, '/horticulture');
  }  else if (index == 5) {
  Navigator.pushNamed(context, '/knowledge-base');
} else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${m['label']} — coming soon!'),
        behavior: SnackBarBehavior.floating,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
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
        );
      },
    );
  }
}
