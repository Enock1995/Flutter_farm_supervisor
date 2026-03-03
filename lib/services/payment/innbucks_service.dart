// lib/services/payment/innbucks_service.dart
// Innbucks Zimbabwe
// Developed by Sir Enocks — Cor Technologies

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_service.dart';

class InnbucksService {
  // ── Replace with your Innbucks merchant credentials ───
  static const String _merchantCode = 'YOUR_INNBUCKS_MERCHANT_CODE';
  static const String _merchantPin  = 'YOUR_INNBUCKS_MERCHANT_PIN';
  static const String _baseUrl      = 'https://api.innbucks.co.zw/v1';
  static const double _amount       = 2.50;
  static const String _currency     = 'USD';

  Future<PaymentInitResult> initiate({
    required String userId,
    required String phone,
  }) async {
    try {
      final reference =
          'AGRIC-$userId-${DateTime.now().millisecondsSinceEpoch}';

      final response = await http.post(
        Uri.parse('$_baseUrl/payment/request'),
        headers: {
          'Content-Type': 'application/json',
          'X-Merchant-Code': _merchantCode,
          'X-Merchant-Pin':  _merchantPin,
        },
        body: jsonEncode({
          'phone':       _normalisePhone(phone),
          'amount':      _amount,
          'currency':    _currency,
          'reference':   reference,
          'description': 'AgricAssist ZW Lifetime Subscription',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PaymentInitResult(
          success: true,
          pollReference: data['transaction_id'] ?? reference,
          instructions:
              'An Innbucks payment request has been sent to $phone. '
              'Approve it in your Innbucks app or dial *405#.',
        );
      } else {
        final err = jsonDecode(response.body);
        return PaymentInitResult(
          success: false,
          errorMessage: err['message'] ??
              'Innbucks payment failed. Please try again.',
        );
      }
    } catch (e) {
      return PaymentInitResult(
        success: false,
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<bool> pollStatus(String transactionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment/status/$transactionId'),
        headers: {
          'X-Merchant-Code': _merchantCode,
          'X-Merchant-Pin':  _merchantPin,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status =
            (data['status'] ?? '').toString().toLowerCase();
        return status == 'paid' ||
            status == 'success' ||
            status == 'completed';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String _normalisePhone(String phone) {
    if (phone.startsWith('0')) {
      return '263${phone.substring(1)}';
    }
    return phone;
  }
}