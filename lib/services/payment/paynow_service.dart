// lib/services/payment/paynow_service.dart
// Paynow Zimbabwe — EcoCash & OneMoney
// Developed by Sir Enocks — Cor Technologies

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'payment_service.dart';

class PaynowService {
  // ── Replace with your Paynow merchant credentials ─────
  static const String _integrationId   = 'YOUR_PAYNOW_INTEGRATION_ID';
  static const String _integrationKey  = 'YOUR_PAYNOW_INTEGRATION_KEY';
  static const String _returnUrl       =
      'https://agricassist.co.zw/payment/return';
  static const String _resultUrl       =
      'https://agricassist.co.zw/payment/result';
  static const double _amount          = 2.50;
  static const String _currency        = 'USD';

  static const String _initUrl =
      'https://www.paynow.co.zw/interface/initiatetransaction';
  static const String _pollUrl =
      'https://www.paynow.co.zw/interface/remotetransaction';

  // ── Initiate Paynow mobile payment ────────────────────
  Future<PaymentInitResult> initiate({
    required String method,
    required String userId,
    required String phone,
    required String email,
  }) async {
    try {
      final reference = 'AGRIC-$userId-${DateTime.now().millisecondsSinceEpoch}';

      final fields = {
        'id':          _integrationId,
        'reference':   reference,
        'amount':      _amount.toStringAsFixed(2),
        'additionalinfo': 'AgricAssist ZW Lifetime Subscription',
        'returnurl':   _returnUrl,
        'resulturl':   _resultUrl,
        'authemail':   email,
        'phone':       _normalisePhone(phone),
        'method':      method == 'ecocash' ? 'ecocash' : 'onemoney',
        'status':      'Message',
      };

      fields['hash'] = _buildHash(fields);

      final response = await http.post(
        Uri.parse(_initUrl),
        body: fields,
      ).timeout(const Duration(seconds: 30));

      final parsed = _parseResponse(response.body);

      if (parsed['status']?.toLowerCase() == 'ok') {
        return PaymentInitResult(
          success: true,
          pollReference: parsed['pollurl'],
          instructions:
              'A payment prompt has been sent to $phone. '
              'Enter your ${method == 'ecocash' ? 'EcoCash' : 'OneMoney'} PIN to confirm.',
        );
      } else {
        return PaymentInitResult(
          success: false,
          errorMessage: parsed['error'] ??
              'Paynow initiation failed. Please try again.',
        );
      }
    } catch (e) {
      return PaymentInitResult(
        success: false,
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  // ── Poll Paynow for payment status ────────────────────
  Future<bool> pollStatus(String pollUrl) async {
    try {
      final response = await http.post(
        Uri.parse(pollUrl),
      ).timeout(const Duration(seconds: 15));

      final parsed = _parseResponse(response.body);
      final status = parsed['status']?.toLowerCase() ?? '';
      return status == 'paid' || status == 'awaiting delivery';
    } catch (_) {
      return false;
    }
  }

  // ── Hash builder ──────────────────────────────────────
  String _buildHash(Map<String, String> fields) {
    final values = fields.values.join('');
    final input = values + _integrationKey;
    return sha512.convert(utf8.encode(input)).toString().toUpperCase();
  }

  // ── Parse URL-encoded response ────────────────────────
  Map<String, String> _parseResponse(String body) {
    final result = <String, String>{};
    for (final pair in body.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        result[Uri.decodeComponent(parts[0])] =
            Uri.decodeComponent(parts[1]);
      }
    }
    return result;
  }

  String _normalisePhone(String phone) {
    // Convert 07XXXXXXXX → 2637XXXXXXXX
    if (phone.startsWith('0')) {
      return '263${phone.substring(1)}';
    }
    return phone;
  }
}