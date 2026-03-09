// lib/screens/paywall/paywall_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../services/subscription_service.dart';
import 'payment_screen.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final daysLeft = SubscriptionService.trialDaysRemaining(user);
    final isExpired = SubscriptionService.isSoftLocked(user);

    // Allow back navigation if user came from dashboard (not soft-locked)
    final canGoBack = !isExpired;

    return PopScope(
      canPop: canGoBack,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Back button (only when not expired) ──
                if (canGoBack)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.textSecondary),
                      label: Text('Back to Dashboard',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary)),
                    ),
                  ),

                const SizedBox(height: 8),

                // ── Header ──────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryDark,
                        AppColors.primary
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('🌽',
                          style: TextStyle(fontSize: 52)),
                      const SizedBox(height: 12),
                      Text(
                        isExpired
                            ? 'Your Free Trial Has Ended'
                            : '$daysLeft Days Left in Trial',
                        style: AppTextStyles.heading2
                            .copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isExpired
                            ? 'Unlock full access with a one-time payment'
                            : 'Subscribe now to keep uninterrupted access',
                        style: AppTextStyles.body
                            .copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Price card ───────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text('One-Time Lifetime Access',
                          style: AppTextStyles.heading3
                              .copyWith(
                                  color:
                                      AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('\$',
                              style: AppTextStyles.body
                                  .copyWith(
                                      color: AppColors.primary,
                                      fontSize: 22,
                                      fontWeight:
                                          FontWeight.w700)),
                          Text('2',
                              style: AppTextStyles.heading1
                                  .copyWith(
                                      color: AppColors.primary,
                                      fontSize: 64)),
                          Text('.99',
                              style: AppTextStyles.body
                                  .copyWith(
                                      color: AppColors.primary,
                                      fontSize: 28,
                                      fontWeight:
                                          FontWeight.w700)),
                        ],
                      ),
                      Text('USD · Pay once, use forever 🇿🇼',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── All modules list ─────────────────────
                _FeatureRow(
                    icon: Icons.eco,
                    text: 'Crop Management'),
                _FeatureRow(
                    icon: Icons.pets,
                    text: 'Livestock Management'),
                _FeatureRow(
                    icon: Icons.local_florist_outlined,
                    text: 'Horticulture'),
                _FeatureRow(
                    icon: Icons.wb_sunny_outlined,
                    text: 'Weather Forecasts'),
                _FeatureRow(
                    icon: Icons.storefront_outlined,
                    text: 'Market Prices'),
                _FeatureRow(
                    icon: Icons.newspaper_outlined,
                    text: 'Agri News'),
                _FeatureRow(
                    icon: Icons.account_balance_wallet_outlined,
                    text: 'Finance & Expense Tracking'),
                _FeatureRow(
                    icon: Icons.calendar_month_outlined,
                    text: 'Farm Calendar'),
                _FeatureRow(
                    icon: Icons.people_outline,
                    text: 'Labour Tracker'),
                _FeatureRow(
                    icon: Icons.bug_report_outlined,
                    text: 'Pest & Disease Advisor'),
                _FeatureRow(
                    icon: Icons.water_drop_outlined,
                    text: 'Irrigation Manager'),
                _FeatureRow(
                    icon: Icons.layers_outlined,
                    text: 'Soil Management'),
                _FeatureRow(
                    icon: Icons.calculate_outlined,
                    text: 'Input Calculator'),
                _FeatureRow(
                    icon: Icons.picture_as_pdf_outlined,
                    text: 'Reports & Export'),
                _FeatureRow(
                    icon: Icons.menu_book_outlined,
                    text: 'Knowledge Base'),
                _FeatureRow(
                    icon: Icons.update,
                    text: 'All future updates included'),

                const SizedBox(height: 28),

                // ── Payment method buttons ───────────────
                Text('Choose Payment Method',
                    style: AppTextStyles.heading3),
                const SizedBox(height: 16),

                // EcoCash
                _PaymentButton(
                  label: 'Pay with EcoCash',
                  subtitle: 'Zimbabwe mobile money',
                  color: const Color(0xFFCC0000),
                  icon: Icons.phone_android,
                  onTap: () => _openPayment(
                      context, 'ecocash'),
                ),
                const SizedBox(height: 10),

                // ZB Bank
                _PaymentButton(
                  label: 'Pay with ZB Bank',
                  subtitle: 'ZB Bank internet banking',
                  color: const Color(0xFF1A237E),
                  icon: Icons.account_balance,
                  onTap: () => _openPayment(
                      context, 'zbbank'),
                ),

                const SizedBox(height: 28),

                // ── Logout option ────────────────────────
                TextButton(
                  onPressed: () =>
                      context.read<AuthProvider>().logout(),
                  child: Text(
                    'Log out',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPayment(BuildContext context, String gateway) {
    context.read<PaymentProvider>().reset();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(gateway: gateway),
      ),
    );
  }
}

// ── Feature row widget ────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.body),
          ),
          const Icon(Icons.check_circle,
              color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}

// ── Payment button widget ─────────────────────────────────
class _PaymentButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _PaymentButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(
                              color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}