// lib/screens/paywall/paywall_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../services/subscription_service.dart';
import 'payment_screen.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final trialDaysLeft = SubscriptionService.trialDaysRemaining(user);
    final isCoreExpired = SubscriptionService.isSoftLocked(user);
    final isPremiumExpired = !SubscriptionService.isTrialActive(user) &&
        SubscriptionService.isPremiumLocked(user);
    final canGoBack = !isCoreExpired;

    // Auto-select tab: if core not subscribed, show base tab; else show premium
    if (user.isSubscribed && !_tabController.indexIsChanging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.index = 1;
      });
    }

    return PopScope(
      canPop: canGoBack,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────
              _buildHeader(
                  user, trialDaysLeft, isCoreExpired, isPremiumExpired, canGoBack),

              // ── Tab bar ───────────────────────────────
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Base Plan',
                              style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700)),
                          Text('\$2.99 one-time',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Tab(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Premium Plan',
                              style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700)),
                          Text('\$1.99 / 2 months',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab content ───────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBaseTab(user, isCoreExpired),
                    _buildPremiumTab(user, isPremiumExpired),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────
  Widget _buildHeader(user, int trialDays, bool isCoreExpired,
      bool isPremiumExpired, bool canGoBack) {
    String title;
    String subtitle;
    if (isCoreExpired) {
      title = 'Trial Ended — Keep Access';
      subtitle = 'Choose a plan to continue using AgricAssist ZW';
    } else if (isPremiumExpired) {
      title = 'Premium Access Expired';
      subtitle = 'Renew for \$1.99 to unlock premium features';
    } else {
      title = '$trialDays Days Left in Trial';
      subtitle = 'Subscribe now for uninterrupted access';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canGoBack)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 4),
                  Text('Back',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white70)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('🌽', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.heading3
                            .copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── BASE PLAN TAB ($2.99 lifetime) ────────────────────
  Widget _buildBaseTab(user, bool isCoreExpired) {
    final alreadySubscribed = user.isSubscribed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Price card
          _PriceCard(
            title: 'Base Plan — Lifetime Access',
            price: '\$2.99',
            period: 'One-time payment · Never expires 🇿🇼',
            color: AppColors.primary,
            badge: alreadySubscribed ? '✅ Active' : null,
          ),
          const SizedBox(height: 20),

          // What's included
          _SectionLabel(label: '✅ 15 Core Modules — Included Forever'),
          const SizedBox(height: 10),
          ..._coreModules.map((m) => _FeatureRow(
              icon: m['icon'] as IconData,
              text: m['text'] as String,
              color: AppColors.primary)),

          const SizedBox(height: 8),
          _FeatureRow(
              icon: Icons.update,
              text: 'All future core module updates',
              color: AppColors.primary),

          const SizedBox(height: 24),

          if (alreadySubscribed)
            _ActiveBadge(
                message:
                    'You have lifetime access to all 15 core modules.')
          else ...[
            Text('Pay via', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            _PaymentButton(
              label: 'Pay with EcoCash',
              subtitle: 'Zimbabwe mobile money · \$2.99',
              color: const Color(0xFFCC0000),
              icon: Icons.phone_android,
              onTap: () =>
                  _openPayment(context, 'ecocash', isPremium: false),
            ),
            const SizedBox(height: 10),
            _PaymentButton(
              label: 'Pay with ZB Bank',
              subtitle: 'ZB Bank internet banking · \$2.99',
              color: const Color(0xFF1A237E),
              icon: Icons.account_balance,
              onTap: () =>
                  _openPayment(context, 'zbbank', isPremium: false),
            ),
          ],

          const SizedBox(height: 24),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  // ── PREMIUM PLAN TAB ($1.99 / 60 days) ───────────────
  Widget _buildPremiumTab(user, bool isPremiumExpired) {
    final hasPremium = user.hasPremiumAccess;
    final daysLeft = user.premiumDaysRemaining;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Price card
          _PriceCard(
            title: 'Premium Plan — All Features',
            price: '\$1.99',
            period: 'Every 2 months · Auto-lock after 60 days',
            color: const Color(0xFF7B2D8B),
            badge: hasPremium
                ? '👑 Active · $daysLeft days left'
                : isPremiumExpired
                    ? '⚠️ Expired'
                    : null,
          ),
          const SizedBox(height: 12),

          // Renewal reminder box
          if (hasPremium && daysLeft <= 14)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Premium expires in $daysLeft days. Renew now to stay uninterrupted.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),

          if (isPremiumExpired)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outlined,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your premium access has expired. Renew for \$1.99 to unlock all premium modules.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          _SectionLabel(label: '👑 Everything in Base, plus:'),
          const SizedBox(height: 10),
          ..._premiumModules.map((m) => _FeatureRow(
              icon: m['icon'] as IconData,
              text: m['text'] as String,
              color: const Color(0xFF7B2D8B))),

          const SizedBox(height: 8),
          // Renewal note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7B2D8B).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF7B2D8B).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF7B2D8B), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Premium locks every 60 days. Pay \$1.99 to renew and keep all premium features active.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: const Color(0xFF7B2D8B)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (!user.isSubscribed)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Get the Base Plan first (\$2.99), then add Premium on top.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _tabController.index = 0,
                    child: const Text('Base Plan'),
                  ),
                ],
              ),
            ),

          Text('Pay via', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          _PaymentButton(
            label: 'Pay with EcoCash',
            subtitle: 'Zimbabwe mobile money · \$1.99',
            color: const Color(0xFFCC0000),
            icon: Icons.phone_android,
            onTap: user.isSubscribed
                ? () => _openPayment(context, 'ecocash',
                    isPremium: true)
                : null,
          ),
          const SizedBox(height: 10),
          _PaymentButton(
            label: 'Pay with ZB Bank',
            subtitle: 'ZB Bank internet banking · \$1.99',
            color: const Color(0xFF1A237E),
            icon: Icons.account_balance,
            onTap: user.isSubscribed
                ? () =>
                    _openPayment(context, 'zbbank', isPremium: true)
                : null,
          ),

          const SizedBox(height: 24),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  void _openPayment(BuildContext context, String gateway,
      {required bool isPremium}) {
    context.read<PaymentProvider>().reset();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          gateway: gateway,
          isPremium: isPremium,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: () => context.read<AuthProvider>().logout(),
      child: Text('Log out',
          style: AppTextStyles.body
              .copyWith(color: AppColors.textSecondary)),
    );
  }
}

// ── Core modules list ─────────────────────────────────────
const _coreModules = [
  {'icon': Icons.eco, 'text': 'Crop Management'},
  {'icon': Icons.pets, 'text': 'Livestock Management'},
  {'icon': Icons.local_florist_outlined, 'text': 'Horticulture'},
  {'icon': Icons.wb_sunny_outlined, 'text': 'Weather Forecasts'},
  {'icon': Icons.storefront_outlined, 'text': 'Market Prices'},
  {'icon': Icons.newspaper_outlined, 'text': 'Agri News'},
  {'icon': Icons.account_balance_wallet_outlined, 'text': 'Finance & Expense Tracking'},
  {'icon': Icons.calendar_month_outlined, 'text': 'Farm Calendar'},
  {'icon': Icons.people_outline, 'text': 'Labour Tracker'},
  {'icon': Icons.bug_report_outlined, 'text': 'Pest & Disease Advisor'},
  {'icon': Icons.water_drop_outlined, 'text': 'Irrigation Manager'},
  {'icon': Icons.layers_outlined, 'text': 'Soil Management'},
  {'icon': Icons.calculate_outlined, 'text': 'Input Calculator'},
  {'icon': Icons.picture_as_pdf_outlined, 'text': 'Reports & Export'},
  {'icon': Icons.menu_book_outlined, 'text': 'Knowledge Base'},
];

// ── Premium modules list ──────────────────────────────────
const _premiumModules = [
  {'icon': Icons.medical_services_outlined, 'text': 'AI Crop & Livestock Diagnosis'},
  {'icon': Icons.trending_up, 'text': 'AI Yield Prediction'},
  {'icon': Icons.smart_toy_outlined, 'text': 'AI Farm Advisory Chat'},
  {'icon': Icons.bar_chart_outlined, 'text': 'Advanced Analytics'},
  {'icon': Icons.summarize_outlined, 'text': 'Auto PDF/Excel Reports'},
  {'icon': Icons.corporate_fare_outlined, 'text': 'Multi-Farm Management'},
  {'icon': Icons.add_location_alt_outlined, 'text': 'Farm Registration & GPS'},
  {'icon': Icons.group_add_outlined, 'text': 'Worker Onboarding'},
  {'icon': Icons.location_on_outlined, 'text': 'GPS Clock-In/Out'},
  {'icon': Icons.payments_outlined, 'text': 'Payroll & EcoCash Payout'},
  {'icon': Icons.notifications_active_outlined, 'text': 'Hyperlocal Weather Alerts'},
  {'icon': Icons.schedule_outlined, 'text': 'Smart Irrigation Scheduling'},
  {'icon': Icons.satellite_alt_outlined, 'text': 'GPS Field Mapping'},
  {'icon': Icons.price_change_outlined, 'text': 'Cost vs Market Analysis'},
  {'icon': Icons.verified_user_outlined, 'text': 'AGRITEX Mudhumeni Network'},
];

// ── Reusable widgets ──────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final Color color;
  final String? badge;
  const _PriceCard({
    required this.title,
    required this.price,
    required this.period,
    required this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge!,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            const SizedBox(height: 10),
          ],
          Text(title,
              style: AppTextStyles.heading3
                  .copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('\$',
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              Text(price.replaceAll('\$', ''),
                  style: TextStyle(
                      color: color,
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      height: 1)),
            ],
          ),
          Text(period,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label,
          style: AppTextStyles.body
              .copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _FeatureRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.body)),
          Icon(Icons.check_circle, color: color, size: 18),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final String message;
  const _ActiveBadge({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.success)),
          ),
        ],
      ),
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _PaymentButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}