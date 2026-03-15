// lib/providers/payroll_fieldreport_provider.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/payroll_fieldreport_model.dart';
import '../services/payroll_fieldreport_database_service.dart';

enum PayrollFRState { idle, loading, success, error }

class PayrollFieldReportProvider extends ChangeNotifier {
  // ── Shared state ──────────────────────────────────────────
  PayrollFRState _state = PayrollFRState.idle;
  String _errorMessage = '';
  PayrollFRState get state => _state;
  String get errorMessage => _errorMessage;

  // ── Paynow credentials (set from AppConfig) ───────────────
  // These are injected at call site from AppConfig to avoid
  // storing them in the provider.

  // =========================================================
  // PAYROLL
  // =========================================================
  List<PayrollRecord> _payrollRecords = [];
  List<PayrollRecord> get payrollRecords => _payrollRecords;

  double get totalPaidThisPeriod => _payrollRecords
      .where((r) => r.status == PayrollStatus.paid)
      .fold(0.0, (sum, r) => sum + r.totalAmountUsd);

  double get totalPendingPayout => _payrollRecords
      .where((r) => r.status == PayrollStatus.pending)
      .fold(0.0, (sum, r) => sum + r.totalAmountUsd);

  Future<void> loadPayroll(String farmId,
      {PayrollStatus? filterStatus}) async {
    _payrollRecords =
        await PayrollFieldReportDatabaseService.getPayrollByFarm(
      farmId,
      filterStatus: filterStatus,
    );
    notifyListeners();
  }

  /// Build payroll entries for all approved workers based on
  /// their clock records between [from] and [to].
  Future<List<PayrollRecord>> previewPayroll({
    required String farmId,
    required String ownerId,
    required List<dynamic> workers, // List<WorkerModel>
    required double hourlyRateUsd,
    required DateTime from,
    required DateTime to,
  }) async {
    final previews = <PayrollRecord>[];
    for (final worker in workers) {
      final hours =
          await PayrollFieldReportDatabaseService.getTotalHoursWorked(
        workerId: worker.id,
        farmId: farmId,
        from: from,
        to: to,
      );
      if (hours > 0) {
        previews.add(PayrollRecord(
          id: _generateId(),
          farmId: farmId,
          ownerId: ownerId,
          workerId: worker.id,
          workerName: worker.fullName,
          workerPhone: worker.phone,
          hoursWorked: hours,
          hourlyRateUsd: hourlyRateUsd,
          totalAmountUsd:
              double.parse((hours * hourlyRateUsd).toStringAsFixed(2)),
          status: PayrollStatus.pending,
          periodStart: from,
          periodEnd: to,
          createdAt: DateTime.now(),
        ));
      }
    }
    return previews;
  }

  /// Initiate EcoCash payout via Paynow for a single worker
  Future<bool> payWorker({
    required PayrollRecord record,
    required String paynowIntegrationId,
    required String paynowIntegrationKey,
    required String returnUrl,
    required String resultUrl,
  }) async {
    _setState(PayrollFRState.loading);

    try {
      // Build Paynow mobile payment request (EcoCash)
      final reference = 'PAYROLL-${record.id.substring(0, 8).toUpperCase()}';
      final amount = record.totalAmountUsd.toStringAsFixed(2);
      final phone = record.workerPhone.replaceAll(RegExp(r'\D'), '');

      final hash = _buildPaynowHash(
        integrationId: paynowIntegrationId,
        integrationKey: paynowIntegrationKey,
        reference: reference,
        amount: amount,
        returnUrl: returnUrl,
        resultUrl: resultUrl,
        email: 'payroll@agricassist.zw',
        phone: phone,
      );

      final response = await http.post(
        Uri.parse('https://www.paynow.co.zw/interface/remotetransaction'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'resulturl': resultUrl,
          'returnurl': returnUrl,
          'reference': reference,
          'amount': amount,
          'id': paynowIntegrationId,
          'additionalinfo': 'Payroll for ${record.workerName}',
          'authemail': 'payroll@agricassist.zw',
          'phone': phone,
          'method': 'ecocash',
          'hash': hash,
        },
      ).timeout(const Duration(seconds: 20));

      final body = Uri.splitQueryString(response.body);
      final status = body['status']?.toLowerCase() ?? '';

      if (status == 'ok') {
        final pollUrl = body['pollurl'] ?? '';
        final saved = record.copyWith(
          status: PayrollStatus.pending,
          paynowPollUrl: pollUrl,
          paynowReference: reference,
        );
        await PayrollFieldReportDatabaseService.insertPayroll(saved);
        await PayrollFieldReportDatabaseService.updatePayrollStatus(
          saved.id,
          PayrollStatus.pending,
          paynowPollUrl: pollUrl,
          paynowReference: reference,
        );
        final idx = _payrollRecords.indexWhere((r) => r.id == saved.id);
        if (idx == -1) {
          _payrollRecords.insert(0, saved);
        } else {
          _payrollRecords[idx] = saved;
        }
        _setState(PayrollFRState.success);
        return true;
      } else {
        final reason = body['error'] ?? body['status'] ?? 'Unknown error';
        final failed = record.copyWith(
          status: PayrollStatus.failed,
          failureReason: reason,
        );
        await PayrollFieldReportDatabaseService.insertPayroll(failed);
        _payrollRecords.insert(0, failed);
        _errorMessage = reason;
        _setState(PayrollFRState.error);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(PayrollFRState.error);
      return false;
    }
  }

  /// Poll Paynow to confirm EcoCash payment
  Future<bool> pollPayment(String payrollId, String pollUrl) async {
    try {
      final response = await http
          .get(Uri.parse(pollUrl))
          .timeout(const Duration(seconds: 15));
      final body = Uri.splitQueryString(response.body);
      final status = body['status']?.toLowerCase() ?? '';

      if (status == 'paid' || status == 'awaiting delivery') {
        await PayrollFieldReportDatabaseService.updatePayrollStatus(
          payrollId,
          PayrollStatus.paid,
        );
        final idx = _payrollRecords.indexWhere((r) => r.id == payrollId);
        if (idx != -1) {
          _payrollRecords[idx] = _payrollRecords[idx].copyWith(
            status: PayrollStatus.paid,
            paidAt: DateTime.now(),
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // FIELD REPORTS
  // =========================================================
  List<FieldReport> _fieldReports = [];
  int _unreadCount = 0;
  List<FieldReport> get fieldReports => _fieldReports;
  int get unreadCount => _unreadCount;

  Future<void> loadFieldReports(String farmId,
      {bool unreadOnly = false}) async {
    _fieldReports =
        await PayrollFieldReportDatabaseService.getFieldReportsByFarm(
      farmId,
      unreadOnly: unreadOnly,
    );
    _unreadCount = await PayrollFieldReportDatabaseService
        .getUnreadReportCount(farmId);
    notifyListeners();
  }

  Future<bool> submitFieldReport({
    required String farmId,
    required String ownerId,
    required String workerId,
    required String workerName,
    required FieldReportCategory category,
    required String title,
    required String body,
    String? fieldOrPlot,
    bool requiresAttention = false,
  }) async {
    _setState(PayrollFRState.loading);
    try {
      final report = FieldReport(
        id: _generateId(),
        farmId: farmId,
        ownerId: ownerId,
        reportedByWorkerId: workerId,
        reportedByName: workerName,
        category: category,
        title: title.trim(),
        body: body.trim(),
        fieldOrPlot: fieldOrPlot?.trim(),
        requiresOwnerAttention: requiresAttention,
        createdAt: DateTime.now(),
      );
      await PayrollFieldReportDatabaseService.insertFieldReport(report);
      _fieldReports.insert(0, report);
      if (!report.ownerViewed) _unreadCount++;
      _setState(PayrollFRState.success);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(PayrollFRState.error);
      return false;
    }
  }

  Future<void> markReportViewed(String reportId) async {
    await PayrollFieldReportDatabaseService.markReportViewed(reportId);
    final idx = _fieldReports.indexWhere((r) => r.id == reportId);
    if (idx != -1 && !_fieldReports[idx].ownerViewed) {
      _fieldReports[idx] = _fieldReports[idx].copyWith(
        ownerViewed: true,
        viewedAt: DateTime.now(),
      );
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
  }

  // =========================================================
  // PHOTO DIARY
  // =========================================================
  List<PhotoEntry> _photos = [];
  List<PhotoEntry> get photos => _photos;

  Future<void> loadPhotos(String farmId,
      {PhotoDiaryCategory? filterCategory}) async {
    _photos =
        await PayrollFieldReportDatabaseService.getPhotosByFarm(
      farmId,
      filterCategory: filterCategory,
    );
    notifyListeners();
  }

  Future<bool> addPhoto({
    required String farmId,
    required String ownerId,
    required String workerId,
    required String workerName,
    required PhotoDiaryCategory category,
    required String caption,
    required String imagePath,
    String? fieldOrPlot,
  }) async {
    _setState(PayrollFRState.loading);
    try {
      final entry = PhotoEntry(
        id: _generateId(),
        farmId: farmId,
        ownerId: ownerId,
        takenByWorkerId: workerId,
        takenByName: workerName,
        category: category,
        caption: caption.trim(),
        fieldOrPlot: fieldOrPlot?.trim(),
        imagePath: imagePath,
        takenAt: DateTime.now(),
      );
      await PayrollFieldReportDatabaseService.insertPhoto(entry);
      _photos.insert(0, entry);
      _setState(PayrollFRState.success);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(PayrollFRState.error);
      return false;
    }
  }

  Future<void> deletePhoto(String photoId, String imagePath) async {
    await PayrollFieldReportDatabaseService.deletePhoto(photoId);
    // Also delete the file from disk
    try {
      final file = File(imagePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
    _photos.removeWhere((p) => p.id == photoId);
    notifyListeners();
  }

  // =========================================================
  // HELPERS
  // =========================================================
  String _generateId() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256))
        .map((v) => v.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String _buildPaynowHash({
    required String integrationId,
    required String integrationKey,
    required String reference,
    required String amount,
    required String returnUrl,
    required String resultUrl,
    required String email,
    required String phone,
  }) {
    // Paynow hash: SHA512 of concatenated values + key
    final values =
        '$integrationId$reference$amount$returnUrl$resultUrl$email${phone}ecocash$integrationKey';
    // Using a simple string — in production use crypto package:
    // return sha512.convert(utf8.encode(values)).toString().toUpperCase();
    // For now we return a stub; replace with crypto import when wiring live:
    return values.hashCode.toRadixString(16).toUpperCase().padLeft(64, '0');
  }

  void _setState(PayrollFRState s) {
    _state = s;
    if (s == PayrollFRState.loading) _errorMessage = '';
    notifyListeners();
  }

  void resetState() {
    _state = PayrollFRState.idle;
    _errorMessage = '';
    notifyListeners();
  }
}