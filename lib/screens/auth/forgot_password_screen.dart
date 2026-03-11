// lib/screens/auth/forgot_password_screen.dart
// Developed by Sir Enocks — Cor Technologies
// Password reset via security question — no server needed.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1; // 1 = enter phone, 2 = answer question, 3 = new password
  String? _securityQuestion;
  bool _obscureAnswer = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // Step 1 — look up phone & fetch security question
  Future<void> _lookupPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      _showError('Please enter a valid phone number.');
      return;
    }
    setState(() => _isLoading = true);
    final question =
        await context.read<AuthProvider>().getSecurityQuestion(phone);
    setState(() => _isLoading = false);

    if (question == null || question.isEmpty) {
      _showError(
          'No account found with that phone number, or no security question was set.');
      return;
    }
    setState(() {
      _securityQuestion = question;
      _step = 2;
    });
  }

  // Step 2 — verify security answer
  Future<void> _verifyAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      _showError('Please enter your security answer.');
      return;
    }
    setState(() => _isLoading = true);
    final correct = await context.read<AuthProvider>().verifySecurityAnswer(
          _phoneController.text.trim(),
          answer,
        );
    setState(() => _isLoading = false);

    if (!correct) {
      _showError('Incorrect answer. Please try again.');
      return;
    }
    setState(() => _step = 3);
  }

  // Step 3 — set new password
  Future<void> _resetPassword() async {
    final newPw = _newPasswordController.text;
    if (newPw.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (newPw != _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }
    setState(() => _isLoading = true);
    final success = await context.read<AuthProvider>().resetPassword(
          _phoneController.text.trim(),
          newPw,
        );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Password Reset'),
          content: const Text(
              'Your password has been reset successfully. Please log in with your new password.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to login
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } else {
      _showError('Reset failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress steps
            _buildStepIndicator(),
            const SizedBox(height: 28),

            if (_step == 1) _buildStep1(),
            if (_step == 2) _buildStep2(),
            if (_step == 3) _buildStep3(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (i) {
        final stepNum = i + 1;
        final isActive = _step == stepNum;
        final isDone = _step > stepNum;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.success
                      : isActive
                          ? AppColors.primary
                          : AppColors.divider,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 16)
                      : Text('$stepNum',
                          style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textHint,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                ),
              ),
              if (i < 2)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isDone
                        ? AppColors.success
                        : AppColors.divider,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ── Step 1: Enter phone ───────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Find Your Account', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text(
          'Enter the phone number you registered with.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'e.g. 0771234567',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Find Account',
          icon: Icons.search,
          isLoading: _isLoading,
          onPressed: _lookupPhone,
        ),
      ],
    );
  }

  // ── Step 2: Answer security question ─────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verify Your Identity', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text(
          'Answer the security question you set during registration.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 24),

        // Show the question
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Security Question',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Text(
                _securityQuestion ?? '',
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        CustomTextField(
          controller: _answerController,
          label: 'Your Answer',
          hint: 'Type your answer',
          prefixIcon: Icons.lock_person_outlined,
          obscureText: _obscureAnswer,
          helperText: 'Not case-sensitive',
          suffixIcon: IconButton(
            icon: Icon(
                _obscureAnswer
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: AppColors.textSecondary),
            onPressed: () =>
                setState(() => _obscureAnswer = !_obscureAnswer),
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Verify Answer',
          icon: Icons.verified_outlined,
          isLoading: _isLoading,
          onPressed: _verifyAnswer,
        ),
      ],
    );
  }

  // ── Step 3: New password ──────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set New Password', style: AppTextStyles.heading3),
        const SizedBox(height: 4),
        Text(
          'Choose a new password for your account.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 24),
        CustomTextField(
          controller: _newPasswordController,
          label: 'New Password',
          hint: 'Minimum 6 characters',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureNew,
          suffixIcon: IconButton(
            icon: Icon(
                _obscureNew ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary),
            onPressed: () =>
                setState(() => _obscureNew = !_obscureNew),
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm New Password',
          hint: 'Re-enter new password',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirm,
          suffixIcon: IconButton(
            icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: AppColors.textSecondary),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Reset Password',
          icon: Icons.check_circle_outline,
          isLoading: _isLoading,
          onPressed: _resetPassword,
        ),
      ],
    );
  }
}