// lib/services/payment/payment_service.dart
// Developed by Sir Enocks — Cor Technologies
//
// Active gateways:
//   ecocash → Paynow EcoCash mobile push ✅
//   zbbank  → ZB Bank redirect (stub, needs live server) ⏳

import 'paynow_service.dart';

class PaymentInitResult {
  final bool success;
  final String? pollReference;
  final String? errorMessage;
  final String? instructions;

  const PaymentInitResult({
    required this.success,
    this.pollReference,
    this.errorMessage,
    this.instructions,
  });
}

class PaymentService {
  final PaynowService _paynow = PaynowService();

  // ── Initiate payment ──────────────────────────────────
  Future<PaymentInitResult> initiate({
    required String gatewayId,
    required String userId,
    required String phone,
    required String email,
  }) async {
    switch (gatewayId) {
      case 'ecocash':
        return _paynow.initiate(
          userId: userId,
          phone: phone,
          email: email,
        );

      case 'zbbank':
        // ZB Bank needs redirect flow + live server.
        // Stub until backend is ready.
        return const PaymentInitResult(
          success: false,
          errorMessage:
              'ZB Bank payments are coming soon. Please use EcoCash for now.',
        );

      default:
        return const PaymentInitResult(
          success: false,
          errorMessage: 'Unknown payment gateway.',
        );
    }
  }

  // ── Poll for confirmation ─────────────────────────────
  Future<bool> pollStatus({
    required String reference,
    required String gatewayId,
  }) async {
    switch (gatewayId) {
      case 'ecocash':
        return _paynow.pollStatus(reference);
      case 'zbbank':
        return false;
      default:
        return false;
    }
  }
}