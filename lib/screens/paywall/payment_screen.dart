// lib/screens/paywall/payment_screen.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String gateway;
  const PaymentScreen({super.key, required this.gateway});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cardController  = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController   = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Timer? _pollTimer;
  int _pollCount = 0;
  static const int _maxPolls = 24; // 2 minutes max

  @override
  void initState() {
    super.initState();
    // Pre-fill from user profile
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _phoneController.text = user.phone;
      _emailController.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneController.dispose();
    _emailController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String get _gatewayLabel {
    switch (widget.gateway) {
      case 'ecocash':  return 'EcoCash';
      case 'onemoney': return 'OneMoney';
      case 'innbucks': return 'Innbucks';
      case 'stripe':   return 'Card (Stripe)';
      default:         return widget.gateway;
    }
  }

  Color get _gatewayColor {
    switch (widget.gateway) {
      case 'ecocash':  return const Color(0xFFCC0000);
      case 'onemoney': return const Color(0xFF0066CC);
      case 'innbucks': return const Color(0xFFFF6600);
      case 'stripe':   return const Color(0xFF6772E5);
      default:         return AppColors.primary;
    }
  }

  bool get _isMobilePayment =>
      widget.gateway == 'ecocash' ||
      widget.gateway == 'onemoney' ||
      widget.gateway == 'innbucks';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().user!;
    final provider = context.read<PaymentProvider>();

    final result = await provider.initiatePayment(
      gatewayId: widget.gateway,
      userId: user.userId,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    if (result.success) {
      _startPolling();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.errorMessage ?? 'Payment failed'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _startPolling() {
    _pollCount = 0;
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        _pollCount++;
        if (_pollCount > _maxPolls) {
          timer.cancel();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Payment confirmation timed out. Please check and try again.'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          return;
        }

        final user = context.read<AuthProvider>().user!;
        final confirmed = await context
            .read<PaymentProvider>()
            .pollPaymentStatus(userId: user.userId);

        if (confirmed && mounted) {
          timer.cancel();
          // Reload user to get updated subscription status
          await context.read<AuthProvider>().checkSession();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const PaymentSuccessScreen()),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _gatewayColor,
        foregroundColor: Colors.white,
        title: Text('Pay via $_gatewayLabel'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _gatewayColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _gatewayColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline,
                        color: _gatewayColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('AgricAssist ZW — Lifetime',
                              style: AppTextStyles.body
                                  .copyWith(
                                      fontWeight:
                                          FontWeight.w600)),
                          Text('One-time payment · £2.50',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Text('£2.50',
                        style: AppTextStyles.heading3
                            .copyWith(color: _gatewayColor)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (provider.isAwaiting) ...[
                // ── Awaiting confirmation state ──────────
                _buildAwaitingWidget(),
              ] else ...[
                // ── Input form ───────────────────────────
                if (_isMobilePayment) ...[
                  Text('Mobile Number',
                      style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration(
                        'e.g. 0771234567',
                        Icons.phone_android),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter your mobile number';
                      }
                      if (v.length < 9) {
                        return 'Enter a valid Zimbabwe number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Email Address',
                      style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                        'your@email.com', Icons.email_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter your email for receipt';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.info, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'A payment prompt will be sent to '
                            'your $_gatewayLabel number. '
                            'Enter your PIN to confirm.',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Stripe card inputs
                  Text('Card Number',
                      style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _cardController,
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    decoration: _inputDecoration(
                        '1234 5678 9012 3456',
                        Icons.credit_card),
                    validator: (v) => v == null ||
                            v.replaceAll(' ', '').length < 16
                        ? 'Enter valid card number'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('Expiry',
                                style: AppTextStyles.label),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _expiryController,
                              keyboardType:
                                  TextInputType.number,
                              maxLength: 5,
                              decoration: _inputDecoration(
                                  'MM/YY', Icons.date_range),
                              validator: (v) =>
                                  v == null || v.length < 5
                                      ? 'Invalid'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('CVV',
                                style: AppTextStyles.label),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _cvvController,
                              keyboardType:
                                  TextInputType.number,
                              maxLength: 3,
                              obscureText: true,
                              decoration: _inputDecoration(
                                  '123', Icons.lock_outline),
                              validator: (v) =>
                                  v == null || v.length < 3
                                      ? 'Invalid'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Email for receipt',
                      style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                        'your@email.com',
                        Icons.email_outlined),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Enter your email'
                        : null,
                  ),
                ],

                const SizedBox(height: 28),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        provider.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gatewayColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2)
                        : Text(
                            'Pay £2.50 via $_gatewayLabel',
                            style: AppTextStyles.body
                                .copyWith(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w700)),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Center(
                child: Text(
                  '🔒 Secure payment · No recurring charges',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAwaitingWidget() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('Waiting for Payment',
                  style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text(
                'Please approve the payment prompt on '
                'your $_gatewayLabel. '
                'We will confirm automatically.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Checking every 5 seconds...',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            _pollTimer?.cancel();
            context.read<PaymentProvider>().reset();
          },
          child: Text('Cancel & try again',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.error)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textHint),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.white,
      counterText: '',
    );
  }
}