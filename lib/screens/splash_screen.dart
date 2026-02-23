// lib/screens/splash_screen.dart
// Shows the app logo while checking if user is already logged in.
// Redirects to Dashboard (if logged in) or Login (if not).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _animController.forward();

    // Check session after animation starts
    Future.delayed(const Duration(milliseconds: 1800), _checkSession);
  }

  Future<void> _checkSession() async {
    await context.read<AuthProvider>().checkSession();

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final destination = auth.isAuthenticated
        ? const DashboardScreen()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.grass,
                    color: AppColors.primary,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),

                // App name
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.heading1.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appTagline,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 60),

                // Loading indicator
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(height: 60),

                // Zimbabwe flag
                const Text(
                  '🇿🇼',
                  style: TextStyle(fontSize: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}