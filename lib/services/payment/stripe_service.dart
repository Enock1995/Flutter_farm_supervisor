// lib/services/payment/stripe_service.dart
// Stripe — Visa / Mastercard
// Developed by Sir Enocks — Cor Technologies

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_service.dart';

class StripeService {
  // ── Replace with your Stripe keys ─────────────────────
  static const String _secretKey =
      'sk_test_YOUR_STRIPE_SECRET_KEY';
  static const String _currency = 'gbp';
  static const int _amountPence = 250; // £2.50

  // ── Create Stripe PaymentIntent ───────────────────────
  Future<PaymentInitResult> initiate({
    required String userId,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount':   _amountPence.toString(),
          'currency': _currency,
          'description': 'AgricAssist ZW Lifetime Subscription',
          'metadata[user_id]': userId,
          'metadata[email]':   email,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentInitResult(
          success: true,
          pollReference: data['id'],         // PaymentIntent ID
          redirectUrl:   data['client_secret'], // Used by Stripe SDK
          instructions:
              'Enter your card details below to complete payment.',
        );
      } else {
        final err = jsonDecode(response.body);
        return PaymentInitResult(
          success: false,
          errorMessage: err['error']?['message'] ??
              'Stripe error. Please try again.',
        );
      }
    } catch (e) {
      return PaymentInitResult(
        success: false,
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  // ── Poll: check PaymentIntent status ─────────────────
  Future<bool> pollStatus(String paymentIntentId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.stripe.com/v1/payment_intents/$paymentIntentId'),
        headers: {'Authorization': 'Bearer $_secretKey'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'succeeded';
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}