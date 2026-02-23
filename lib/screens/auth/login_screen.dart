// lib/screens/auth/login_screen.dart
// Login screen for existing users.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../dashboard/dashboard_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number.');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final result = await auth.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _showError(result.errorMessage ?? 'Login failed.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo / App name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.grass,
                          color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 16),
                    Text(AppConstants.appName,
                        style: AppTextStyles.heading1
                            .copyWith(color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(AppConstants.appTagline,
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              Text('Welcome Back', style: AppTextStyles.heading2),
              const SizedBox(height: 4),
              Text('Sign in to continue to your farm dashboard.',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 28),

              // Phone
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '0771234567',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Password
              CustomTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 32),

              // Login button
              Consumer<AuthProvider>(
                builder: (context, auth, _) => PrimaryButton(
                  label: 'Sign In',
                  icon: Icons.login,
                  isLoading: auth.isLoading,
                  onPressed: _login,
                ),
              ),
              const SizedBox(height: 20),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: AppTextStyles.body),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegistrationScreen()),
                    ),
                    child: Text(
                      'Register Free',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Zimbabwe flag footer
              const Center(
                child: Text(
                  '🇿🇼 Made for Zimbabwean Farmers',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}