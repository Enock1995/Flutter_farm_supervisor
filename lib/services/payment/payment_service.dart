// lib/services/payment/payment_service.dart
// Developed by Sir Enocks — Cor Technologies

import 'paynow_service.dart';
import 'stripe_service.dart';
import 'innbucks_service.dart';

class PaymentInitResult {
  final bool success;
  final String? pollReference;
  final String? redirectUrl;
  final String? errorMessage;
  final String? instructions;

  const PaymentInitResult({
    required this.success,
    this.pollReference,
    this.redirectUrl,
    this.errorMessage,
    this.instructions,
  });
}

class PaymentService {
  final PaynowService _paynow = PaynowService();
  final StripeService _stripe = StripeService();
  final InnbucksService _innbucks = InnbucksService();

  Future<PaymentInitResult> initiate({
    required String gatewayId,
    required String userId,
    required String phone,
    required String email,
  }) async {
    switch (gatewayId) {
      case 'ecocash':
      case 'onemoney':
        return _paynow.initiate(
          method: gatewayId,
          userId: userId,
          phone: phone,
          email: email,
        );
      case 'stripe':
        return _stripe.initiate(
          userId: userId,
          email: email,
        );
      case 'innbucks':
        return _innbucks.initiate(
          userId: userId,
          phone: phone,
        );
      default:
        return const PaymentInitResult(
          success: false,
          errorMessage: 'Unknown payment gateway.',
        );
    }
  }

  Future<bool> pollStatus({
    required String reference,
    required String gatewayId,
  }) async {
    switch (gatewayId) {
      case 'ecocash':
      case 'onemoney':
        return _paynow.pollStatus(reference);
      case 'stripe':
        return _stripe.pollStatus(reference);
      case 'innbucks':
        return _innbucks.pollStatus(reference);
      default:
        return false;
    }
  }
}