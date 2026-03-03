// lib/providers/payment_provider.dart
// Developed by Sir Enocks — Cor Technologies

import 'package:flutter/foundation.dart';
import '../services/payment/payment_service.dart';
import '../services/database_service.dart';

enum PaymentStatus {
  idle,
  loading,
  awaitingConfirmation,
  success,
  failed,
}

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();
  final DatabaseService _db = DatabaseService();

  PaymentStatus _status = PaymentStatus.idle;
  String? _errorMessage;
  String? _pollReference;
  String? _gateway;

  PaymentStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get pollReference => _pollReference;
  String? get gateway => _gateway;
  bool get isLoading => _status == PaymentStatus.loading;
  bool get isAwaiting =>
      _status == PaymentStatus.awaitingConfirmation;

  // ── Initiate payment ──────────────────────────────────
  Future<PaymentInitResult> initiatePayment({
    required String gatewayId,
    required String userId,
    required String phone,
    required String email,
  }) async {
    _status = PaymentStatus.loading;
    _errorMessage = null;
    _gateway = gatewayId;
    notifyListeners();

    final result = await _paymentService.initiate(
      gatewayId: gatewayId,
      userId: userId,
      phone: phone,
      email: email,
    );

    if (result.success) {
      _pollReference = result.pollReference;
      _status = PaymentStatus.awaitingConfirmation;
    } else {
      _status = PaymentStatus.failed;
      _errorMessage = result.errorMessage;
    }

    notifyListeners();
    return result;
  }

  // ── Poll for payment confirmation ─────────────────────
  Future<bool> pollPaymentStatus({
    required String userId,
  }) async {
    if (_pollReference == null) return false;

    final confirmed = await _paymentService.pollStatus(
      reference: _pollReference!,
      gatewayId: _gateway ?? 'paynow',
    );

    if (confirmed) {
      await _markUserAsSubscribed(userId);
      _status = PaymentStatus.success;
      notifyListeners();
      return true;
    }
    return false;
  }

  // ── Mark subscribed in local DB ───────────────────────
  Future<void> _markUserAsSubscribed(String userId) async {
    final db = await _db.database;
    await db.update(
      'users',
      {'is_subscribed': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ── Manually activate (after confirmed server-side) ──
  Future<void> activateSubscription(String userId) async {
    await _markUserAsSubscribed(userId);
    _status = PaymentStatus.success;
    notifyListeners();
  }

  void reset() {
    _status = PaymentStatus.idle;
    _errorMessage = null;
    _pollReference = null;
    _gateway = null;
    notifyListeners();
  }
}