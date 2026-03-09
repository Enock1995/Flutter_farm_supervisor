// lib/services/payment/paynow_service.dart
// Paynow Zimbabwe — EcoCash mobile push
// Developed by Sir Enocks — Cor Technologies

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import 'payment_service.dart';

class PaynowService {
  // ── Paynow API endpoints ──────────────────────────────
  static const String _initUrl =
      'https://www.paynow.co.zw/interface/remotetransaction';

  // ── Initiate EcoCash mobile push payment ─────────────
  Future<PaymentInitResult> initiate({
    required String userId,
    required String phone,
    required String email,
  }) async {
    try {
      final reference =
          'AGRIC-$userId-${DateTime.now().millisecondsSinceEpoch}';

      // Build fields in exact order Paynow expects
      // Hash must be built before adding 'hash' field to map
      final fields = <String, String>{
        'id':             AppConfig.paynowIntegrationId,
        'reference':      reference,
        'amount':         AppConfig.subscriptionAmountUSD.toStringAsFixed(2),
        'additionalinfo': 'AgricAssist ZW Lifetime Subscription',
        'returnurl':      AppConfig.paynowReturnUrl,
        'resulturl':      AppConfig.paynowResultUrl,
        'authemail':      email.trim(),
        'phone':          _normalisePhone(phone.trim()),
        'method':         'ecocash',
        'status':         'Message',
      };

      // Build and append hash
      fields['hash'] = _buildHash(fields);

      final response = await http.post(
        Uri.parse(_initUrl),
        body: fields,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return PaymentInitResult(
          success: false,
          errorMessage:
              'Paynow server error (${response.statusCode}). Please try again.',
        );
      }

      final parsed = _parseResponse(response.body);
      final status = parsed['status']?.toLowerCase() ?? '';

      if (status == 'ok') {
        return PaymentInitResult(
          success: true,
          pollReference: parsed['pollurl'],
          instructions:
              'A payment prompt has been sent to ${_formatPhone(phone)}. '
              'Enter your EcoCash PIN to confirm.',
        );
      } else {
        // Paynow returns specific error messages — surface them directly
        final errorMsg = parsed['error'] ??
            parsed['status'] ??
            'Paynow initiation failed. Check your phone number and try again.';
        return PaymentInitResult(
          success: false,
          errorMessage: errorMsg,
        );
      }
    } on http.ClientException catch (e) {
      return PaymentInitResult(
        success: false,
        errorMessage: 'Connection failed: ${e.message}. Check your internet.',
      );
    } catch (e) {
      return PaymentInitResult(
        success: false,
        errorMessage: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  // ── Poll Paynow for payment confirmation ──────────────
  Future<bool> pollStatus(String pollUrl) async {
    try {
      if (pollUrl.isEmpty) return false;

      final response = await http.post(
        Uri.parse(pollUrl),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return false;

      final parsed = _parseResponse(response.body);
      final status = parsed['status']?.toLowerCase() ?? '';

      // Verify hash on poll response for security
      final receivedHash = parsed['hash'] ?? '';
      if (receivedHash.isNotEmpty && !_verifyResponseHash(parsed)) {
        // Hash mismatch — possible tampering, reject
        return false;
      }

      return status == 'paid' || status == 'awaiting delivery';
    } catch (_) {
      return false;
    }
  }

  // ── Build SHA-512 hash ────────────────────────────────
  // Paynow spec: concatenate all field VALUES (in order) + integration key
  // then SHA-512 hash the result and uppercase it
  String _buildHash(Map<String, String> fields) {
    final buffer = StringBuffer();
    for (final value in fields.values) {
      buffer.write(value);
    }
    buffer.write(AppConfig.paynowIntegrationKey);
    final bytes = utf8.encode(buffer.toString());
    return sha512.convert(bytes).toString().toUpperCase();
  }

  // ── Verify hash on Paynow response ───────────────────
  bool _verifyResponseHash(Map<String, String> parsed) {
    final receivedHash = parsed['hash'] ?? '';
    if (receivedHash.isEmpty) return true; // no hash to verify

    final fieldsWithoutHash = Map<String, String>.from(parsed)
      ..remove('hash');
    final expectedHash = _buildHash(fieldsWithoutHash);
    return receivedHash.toUpperCase() == expectedHash.toUpperCase();
  }

  // ── Parse URL-encoded Paynow response ─────────────────
  Map<String, String> _parseResponse(String body) {
    final result = <String, String>{};
    for (final pair in body.split('&')) {
      final index = pair.indexOf('=');
      if (index == -1) continue;
      final key   = Uri.decodeComponent(pair.substring(0, index));
      final value = Uri.decodeComponent(pair.substring(index + 1));
      result[key] = value;
    }
    return result;
  }

  // ── Phone normalisation ───────────────────────────────
  // Paynow expects: 2637XXXXXXXX (no + prefix)
  String _normalisePhone(String phone) {
    phone = phone.replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('+')) phone = phone.substring(1);
    if (phone.startsWith('0')) phone = '263${phone.substring(1)}';
    if (!phone.startsWith('263')) phone = '263$phone';
    return phone;
  }

  // ── Format phone for display only ────────────────────
  String _formatPhone(String phone) {
    final n = _normalisePhone(phone);
    if (n.length >= 12) {
      final local = n.substring(3);
      return '+263 ${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5)}';
    }
    return phone;
  }
}