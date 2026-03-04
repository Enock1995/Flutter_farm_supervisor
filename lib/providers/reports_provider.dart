// lib/providers/reports_provider.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/reports_service.dart';

class ReportsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  bool _isLoading = false;
  String? _error;
  GeneratedReport? _currentReport;
  ReportFilter _filter = ReportFilter(
    from: DateTime.now()
        .subtract(const Duration(days: 90)),
    to: DateTime.now(),
  );

  bool get isLoading => _isLoading;
  String? get error => _error;
  GeneratedReport? get currentReport => _currentReport;
  ReportFilter get filter => _filter;

  void updateFilter(ReportFilter f) {
    _filter = f;
    notifyListeners();
  }

  void clearReport() {
    _currentReport = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // GENERATE
  // ---------------------------------------------------------------------------

  Future<void> generate(
    ReportType type,
    String userId,
  ) async {
    _isLoading = true;
    _error = null;
    _currentReport = null;
    notifyListeners();

    try {
      final db = await _db.database;

      switch (type) {
        case ReportType.farmSummary:
          final soil = await _safeQuery(
              db, 'soil_records', userId);
          final setups = await _safeQuery(
              db, 'irrigation_setups', userId);
          final pests = await _safeQuery(
              db, 'farm_alerts', userId);
          final labour = await _safeQuery(
              db, 'labour_sessions', userId);
          _currentReport =
              ReportsService.buildFarmSummary(
            soilRecords: soil,
            irrigationSetups: setups,
            pestAlerts: pests,
            labourSessions: labour,
            filter: _filter,
          );
          break;

        case ReportType.irrigationLog:
          final logs = await _safeQuery(
              db, 'irrigation_logs', userId);
          final setups = await _safeQuery(
              db, 'irrigation_setups', userId);
          _currentReport =
              ReportsService.buildIrrigationLog(
            logs: logs,
            setups: setups,
            filter: _filter,
          );
          break;

        case ReportType.soilHealth:
          final records = await _safeQuery(
              db, 'soil_records', userId);
          _currentReport =
              ReportsService.buildSoilReport(
            records: records,
            filter: _filter,
          );
          break;

        case ReportType.pestAlerts:
          final alerts = await _safeQuery(
              db, 'farm_alerts', userId);
          _currentReport =
              ReportsService.buildPestLog(
            alerts: alerts,
            filter: _filter,
          );
          break;

        case ReportType.labourCosts:
          final sessions = await _safeQuery(
              db, 'labour_sessions', userId);
          _currentReport =
              ReportsService.buildLabourReport(
            sessions: sessions,
            filter: _filter,
          );
          break;

        case ReportType.sprayRecord:
          // Spray records are saved calculations
          final calcs = await _safeQuery(
              db, 'saved_calculations', userId);
          final sprayCalcs = calcs
              .where((c) => c['type'] == 'spray')
              .toList();
          _currentReport = GeneratedReport(
            meta: ReportsService.catalogue.firstWhere(
                (m) => m.type == ReportType.sprayRecord),
            filter: _filter,
            headers: [
              'Product',
              'Summary',
              'Saved Date',
            ],
            rows: sprayCalcs.map((c) {
              final dt = DateTime.tryParse(
                  c['saved_at'] ?? '');
              return ReportRow([
                c['title'] ?? '—',
                c['summary'] ?? '—',
                dt != null
                    ? ReportsService.formatDate(dt)
                    : '—',
              ]);
            }).toList(),
            summary: {
              'Total spray records':
                  '${sprayCalcs.length}',
            },
            generatedAt: DateTime.now(),
          );
          break;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> _safeQuery(
    dynamic db,
    String table,
    String userId,
  ) async {
    try {
      // Check table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table],
      );
      if (tables.isEmpty) return [];
      return await db.query(
        table,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (_) {
      return [];
    }
  }
}