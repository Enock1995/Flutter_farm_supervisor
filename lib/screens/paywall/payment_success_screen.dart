// lib/screens/paywall/payment_success_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';

class PaymentSuccessScreen extends StatelessWidget {
  /// true  → Premium plan activated ($1.99 / 60 days)
  /// false → Base plan activated ($2.99 lifetime)
  final bool isPremium;

  const PaymentSuccessScreen({
    super.key,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final String headline = isPremium
        ? 'Premium Activated! 👑'
        : 'Payment Successful! 🎉';

    final String subtext = isPremium
        ? 'Welcome, ${user?.fullName ?? 'Farmer'}!\n'
          'You now have full access to all Premium features for 60 days.'
        : 'Welcome, ${user?.fullName ?? 'Farmer'}!\n'
          'You now have lifetime access to all 15 core modules.';

    final String footer = isPremium
        ? '🇿🇼 Your premium access renews every 60 days for \$1.99.'
        : '🇿🇼 Thank you for supporting Zimbabwean farming technology.';

    final Color accentColor =
        isPremium ? const Color(0xFF7B2D8B) : AppColors.success;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon circle ──────────────────────────
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 3),
                ),
                child: Icon(
                  isPremium ? Icons.workspace_premium : Icons.check,
                  color: accentColor,
                  size: 60,
                ),
              ),
              const SizedBox(height: 28),

              // ── Headline ─────────────────────────────
              Text(
                headline,
                style: AppTextStyles.heading2.copyWith(color: accentColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Subtext ──────────────────────────────
              Text(
                subtext,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Footer note ──────────────────────────
              Text(
                footer,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // ── Go to Dashboard button ───────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Go to Dashboard',
                    style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}