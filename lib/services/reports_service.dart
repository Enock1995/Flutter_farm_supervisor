// lib/services/reports_service.dart
// Reports & Export — farm summary, activity logs, cost tracking,
// and PDF/CSV export for AgricAssist ZW.
// Developed by Sir Enocks — Cor Technologies

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

enum ReportType {
  farmSummary,
  irrigationLog,
  soilHealth,
  pestAlerts,
  labourCosts,
  sprayRecord,
}

class ReportMeta {
  final ReportType type;
  final String title;
  final String description;
  final String emoji;
  final String color; // hex string for UI

  const ReportMeta({
    required this.type,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
  });
}

class ReportFilter {
  final DateTime? from;
  final DateTime? to;
  final String? plotName;
  final String? crop;

  const ReportFilter({
    this.from,
    this.to,
    this.plotName,
    this.crop,
  });

  ReportFilter copyWith({
    DateTime? from,
    DateTime? to,
    String? plotName,
    String? crop,
  }) =>
      ReportFilter(
        from: from ?? this.from,
        to: to ?? this.to,
        plotName: plotName ?? this.plotName,
        crop: crop ?? this.crop,
      );
}

// A single row of data in a generated report
class ReportRow {
  final List<String> cells;
  const ReportRow(this.cells);
}

class GeneratedReport {
  final ReportMeta meta;
  final ReportFilter filter;
  final List<String> headers;
  final List<ReportRow> rows;
  final Map<String, String> summary; // key: value pairs for summary box
  final DateTime generatedAt;

  const GeneratedReport({
    required this.meta,
    required this.filter,
    required this.headers,
    required this.rows,
    required this.summary,
    required this.generatedAt,
  });

  bool get hasData => rows.isNotEmpty;

  String toCsv() {
    final buf = StringBuffer();
    // Title
    buf.writeln(meta.title);
    buf.writeln(
        'Generated: ${_fmtDate(generatedAt)}');
    if (filter.from != null || filter.to != null) {
      buf.writeln(
          'Period: ${filter.from != null ? _fmtDate(filter.from!) : "All"}'
          ' to ${filter.to != null ? _fmtDate(filter.to!) : "All"}');
    }
    buf.writeln();

    // Summary
    if (summary.isNotEmpty) {
      buf.writeln('SUMMARY');
      for (final e in summary.entries) {
        buf.writeln('${e.key},${e.value}');
      }
      buf.writeln();
    }

    // Headers
    buf.writeln(headers
        .map((h) => '"$h"')
        .join(','));

    // Rows
    for (final row in rows) {
      buf.writeln(row.cells
          .map((c) => '"${c.replaceAll('"', '""')}"')
          .join(','));
    }
    return buf.toString();
  }

  static String _fmtDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// REPORT CATALOGUE
// ---------------------------------------------------------------------------

class ReportsService {
  static const List<ReportMeta> catalogue = [
    ReportMeta(
      type: ReportType.farmSummary,
      title: 'Farm Summary',
      description:
          'Overview of all plots, crops, soil health, and active alerts.',
      emoji: '🏡',
      color: '#2E7D32',
    ),
    ReportMeta(
      type: ReportType.irrigationLog,
      title: 'Irrigation Log',
      description:
          'Water applied per plot — volumes, durations, and totals.',
      emoji: '💧',
      color: '#0288D1',
    ),
    ReportMeta(
      type: ReportType.soilHealth,
      title: 'Soil Health Report',
      description:
          'Soil test results, pH status, nutrient levels, and lime needs.',
      emoji: '🌱',
      color: '#795548',
    ),
    ReportMeta(
      type: ReportType.pestAlerts,
      title: 'Pest & Disease Log',
      description:
          'All reported outbreaks, severity, affected crops, and status.',
      emoji: '🐛',
      color: '#C62828',
    ),
    ReportMeta(
      type: ReportType.labourCosts,
      title: 'Labour Cost Report',
      description:
          'Worker sessions, hours, tasks, and total wages paid.',
      emoji: '👷',
      color: '#F57C00',
    ),
    ReportMeta(
      type: ReportType.sprayRecord,
      title: 'Spray Record',
      description:
          'Pesticide/fungicide applications — products, rates, and areas.',
      emoji: '🧪',
      color: '#6A1B9A',
    ),
  ];

  // ---------------------------------------------------------------------------
  // GENERATE REPORTS FROM LIVE DATA
  // ---------------------------------------------------------------------------

  /// Farm Summary — compiles all module data into one report
  static GeneratedReport buildFarmSummary({
    required List<Map<String, dynamic>> soilRecords,
    required List<Map<String, dynamic>> irrigationSetups,
    required List<Map<String, dynamic>> pestAlerts,
    required List<Map<String, dynamic>> labourSessions,
    required ReportFilter filter,
  }) {
    final now = DateTime.now();

    // Summary stats
    final totalPlots = irrigationSetups.length;
    final activeCrops = irrigationSetups
        .where((s) => s['current_crop'] != null)
        .map((s) => s['current_crop'] as String)
        .toSet()
        .join(', ');
    final soilCount = soilRecords.length;
    final lowPhCount = soilRecords
        .where((r) =>
            r['ph'] != null && (r['ph'] as num) < 5.8)
        .length;
    final activeAlerts = pestAlerts
        .where((a) => (a['is_resolved'] as int? ?? 0) == 0)
        .length;

    final headers = [
      'Module',
      'Item',
      'Value',
      'Status',
    ];

    final rows = <ReportRow>[
      ReportRow(['Irrigation', 'Total irrigated plots', '$totalPlots', '—']),
      ReportRow(['Irrigation', 'Active crops', activeCrops.isEmpty ? 'None assigned' : activeCrops, '—']),
      ReportRow(['Soil', 'Plots tested', '$soilCount', soilCount > 0 ? '✅' : '⚠️ No tests']),
      ReportRow(['Soil', 'Plots needing lime', '$lowPhCount', lowPhCount > 0 ? '🔴 Action needed' : '✅ OK']),
      ReportRow(['Pests', 'Active outbreaks', '$activeAlerts', activeAlerts > 0 ? '🔴 Monitor' : '✅ None']),
      ReportRow(['Labour', 'Total sessions logged', '${labourSessions.length}', '—']),
    ];

    // Per-plot soil detail
    for (final r in soilRecords) {
      final ph = r['ph'];
      rows.add(ReportRow([
        'Soil',
        r['plot_name'] ?? 'Unknown',
        ph != null ? 'pH ${(ph as num).toStringAsFixed(1)}' : 'No pH',
        ph != null && (ph as num) < 5.8 ? '🔴 Needs lime' : '✅',
      ]));
    }

    return GeneratedReport(
      meta: catalogue.firstWhere(
          (m) => m.type == ReportType.farmSummary),
      filter: filter,
      headers: headers,
      rows: rows,
      summary: {
        'Irrigated plots': '$totalPlots',
        'Soil tests recorded': '$soilCount',
        'Plots needing lime': '$lowPhCount',
        'Active pest alerts': '$activeAlerts',
        'Labour sessions': '${labourSessions.length}',
      },
      generatedAt: now,
    );
  }

  // ---------------------------------------------------------------------------

  static GeneratedReport buildIrrigationLog({
    required List<Map<String, dynamic>> logs,
    required List<Map<String, dynamic>> setups,
    required ReportFilter filter,
  }) {
    var filtered = logs.where((l) {
      final date = DateTime.tryParse(
          l['irrigated_at'] ?? '');
      if (date == null) return false;
      if (filter.from != null &&
          date.isBefore(filter.from!)) return false;
      if (filter.to != null &&
          date.isAfter(
              filter.to!.add(const Duration(days: 1))))
        return false;
      if (filter.plotName != null &&
          filter.plotName!.isNotEmpty &&
          l['plot_name'] != filter.plotName) return false;
      return true;
    }).toList();

    filtered.sort((a, b) =>
        (b['irrigated_at'] ?? '').compareTo(
            a['irrigated_at'] ?? ''));

    final totalLitres = filtered.fold<double>(
        0,
        (sum, l) =>
            sum +
            ((l['water_applied_litres'] as num?)
                    ?.toDouble() ??
                0));
    final totalMm = filtered.fold<double>(
        0,
        (sum, l) =>
            sum +
            ((l['water_applied_mm'] as num?)
                    ?.toDouble() ??
                0));
    final totalMins = filtered.fold<double>(
        0,
        (sum, l) =>
            sum +
            ((l['duration_minutes'] as num?)
                    ?.toDouble() ??
                0));

    final headers = [
      'Date',
      'Plot',
      'Duration (min)',
      'Water Applied (L)',
      'Water Applied (mm)',
      'Weather',
      'Notes',
    ];

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final rows = filtered.map((l) {
      final dt =
          DateTime.tryParse(l['irrigated_at'] ?? '');
      final dateStr = dt != null
          ? '${dt.day} ${months[dt.month]} ${dt.year}'
          : '—';
      return ReportRow([
        dateStr,
        l['plot_name'] ?? '—',
        '${(l['duration_minutes'] as num?)?.toStringAsFixed(0) ?? '—'}',
        '${(l['water_applied_litres'] as num?)?.toStringAsFixed(0) ?? '—'}',
        '${(l['water_applied_mm'] as num?)?.toStringAsFixed(2) ?? '—'}',
        _weatherLabel(l['weather_condition']),
        l['notes'] ?? '—',
      ]);
    }).toList();

    return GeneratedReport(
      meta: catalogue.firstWhere(
          (m) => m.type == ReportType.irrigationLog),
      filter: filter,
      headers: headers,
      rows: rows,
      summary: {
        'Total events': '${filtered.length}',
        'Total water': '${(totalLitres / 1000).toStringAsFixed(1)} kL',
        'Total depth': '${totalMm.toStringAsFixed(1)} mm',
        'Total time': '${(totalMins / 60).toStringAsFixed(1)} hrs',
      },
      generatedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------

  static GeneratedReport buildSoilReport({
    required List<Map<String, dynamic>> records,
    required ReportFilter filter,
  }) {
    var filtered = records.where((r) {
      final date =
          DateTime.tryParse(r['test_date'] ?? '');
      if (filter.from != null &&
          date != null &&
          date.isBefore(filter.from!)) return false;
      if (filter.to != null &&
          date != null &&
          date.isAfter(
              filter.to!.add(const Duration(days: 1))))
        return false;
      return true;
    }).toList();

    final headers = [
      'Plot',
      'Test Date',
      'pH',
      'pH Status',
      'N (%)',
      'P (ppm)',
      'K (ppm)',
      'OM (%)',
      'Texture',
      'Area (ha)',
      'Lab',
    ];

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final rows = filtered.map((r) {
      final dt =
          DateTime.tryParse(r['test_date'] ?? '');
      final dateStr = dt != null
          ? '${dt.day} ${months[dt.month]} ${dt.year}'
          : '—';
      final ph = (r['ph'] as num?)?.toDouble();
      String phStatus = '—';
      if (ph != null) {
        if (ph < 4.5) phStatus = 'Extremely Acidic';
        else if (ph < 5.5) phStatus = 'Strongly Acidic';
        else if (ph < 5.8) phStatus = 'Moderately Acidic';
        else if (ph <= 6.8) phStatus = 'Optimal';
        else if (ph <= 7.5) phStatus = 'Slightly Alkaline';
        else phStatus = 'Alkaline';
      }
      return ReportRow([
        r['plot_name'] ?? '—',
        dateStr,
        ph?.toStringAsFixed(1) ?? '—',
        phStatus,
        (r['nitrogen'] as num?) != null
            ? '${((r['nitrogen'] as num) * 100).toStringAsFixed(2)}'
            : '—',
        (r['phosphorus'] as num?)?.toStringAsFixed(1) ?? '—',
        (r['potassium'] as num?)?.toStringAsFixed(0) ?? '—',
        (r['organic_matter'] as num?)?.toStringAsFixed(1) ?? '—',
        r['texture'] ?? '—',
        (r['plot_size_ha'] as num?)?.toStringAsFixed(2) ?? '—',
        r['lab_name'] ?? '—',
      ]);
    }).toList();

    final needLime = filtered
        .where((r) =>
            r['ph'] != null && (r['ph'] as num) < 5.8)
        .length;

    return GeneratedReport(
      meta: catalogue
          .firstWhere((m) => m.type == ReportType.soilHealth),
      filter: filter,
      headers: headers,
      rows: rows,
      summary: {
        'Total tests': '${filtered.length}',
        'Plots needing lime': '$needLime',
        'Optimal pH plots':
            '${filtered.length - needLime}',
      },
      generatedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------

  static GeneratedReport buildPestLog({
    required List<Map<String, dynamic>> alerts,
    required ReportFilter filter,
  }) {
    var filtered = alerts.where((a) {
      final date =
          DateTime.tryParse(a['reported_at'] ?? '');
      if (filter.from != null &&
          date != null &&
          date.isBefore(filter.from!)) return false;
      if (filter.to != null &&
          date != null &&
          date.isAfter(
              filter.to!.add(const Duration(days: 1))))
        return false;
      if (filter.crop != null &&
          filter.crop!.isNotEmpty &&
          a['affected_crop'] != filter.crop) return false;
      return true;
    }).toList();

    filtered.sort((a, b) =>
        (b['reported_at'] ?? '').compareTo(
            a['reported_at'] ?? ''));

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final headers = [
      'Date Reported',
      'Pest / Disease',
      'Affected Crop',
      'Plot / Field',
      'Severity',
      'Status',
      'Notes',
    ];

    final rows = filtered.map((a) {
      final dt =
          DateTime.tryParse(a['reported_at'] ?? '');
      final dateStr = dt != null
          ? '${dt.day} ${months[dt.month]} ${dt.year}'
          : '—';
      return ReportRow([
        dateStr,
        a['pest_disease_name'] ?? '—',
        a['affected_crop'] ?? '—',
        a['plot_or_field'] ?? '—',
        _capitalise(a['severity'] ?? '—'),
        (a['is_resolved'] as int? ?? 0) == 1
            ? 'Resolved'
            : 'Active',
        a['notes'] ?? '—',
      ]);
    }).toList();

    final active = filtered
        .where((a) => (a['is_resolved'] as int? ?? 0) == 0)
        .length;
    final critical = filtered
        .where((a) => a['severity'] == 'critical')
        .length;

    return GeneratedReport(
      meta: catalogue.firstWhere(
          (m) => m.type == ReportType.pestAlerts),
      filter: filter,
      headers: headers,
      rows: rows,
      summary: {
        'Total alerts': '${filtered.length}',
        'Active outbreaks': '$active',
        'Critical events': '$critical',
        'Resolved': '${filtered.length - active}',
      },
      generatedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------

  static GeneratedReport buildLabourReport({
    required List<Map<String, dynamic>> sessions,
    required ReportFilter filter,
  }) {
    var filtered = sessions.where((s) {
      final date =
          DateTime.tryParse(s['work_date'] ?? '');
      if (filter.from != null &&
          date != null &&
          date.isBefore(filter.from!)) return false;
      if (filter.to != null &&
          date != null &&
          date.isAfter(
              filter.to!.add(const Duration(days: 1))))
        return false;
      return true;
    }).toList();

    filtered.sort((a, b) =>
        (b['work_date'] ?? '').compareTo(
            a['work_date'] ?? ''));

    final totalWages = filtered.fold<double>(
        0,
        (sum, s) =>
            sum +
            ((s['amount_paid'] as num?)?.toDouble() ??
                0));
    final totalHours = filtered.fold<double>(
        0,
        (sum, s) =>
            sum +
            ((s['hours_worked'] as num?)?.toDouble() ??
                0));

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final headers = [
      'Date',
      'Worker Name',
      'Task',
      'Hours',
      'Workers',
      'Amount Paid (USD)',
      'Notes',
    ];

    final rows = filtered.map((s) {
      final dt =
          DateTime.tryParse(s['work_date'] ?? '');
      final dateStr = dt != null
          ? '${dt.day} ${months[dt.month]} ${dt.year}'
          : '—';
      return ReportRow([
        dateStr,
        s['worker_name'] ?? s['workers'] ?? '—',
        s['task'] ?? s['task_description'] ?? '—',
        (s['hours_worked'] as num?)?.toStringAsFixed(1) ?? '—',
        '${s['num_workers'] ?? 1}',
        (s['amount_paid'] as num?)?.toStringAsFixed(2) ?? '—',
        s['notes'] ?? '—',
      ]);
    }).toList();

    return GeneratedReport(
      meta: catalogue.firstWhere(
          (m) => m.type == ReportType.labourCosts),
      filter: filter,
      headers: headers,
      rows: rows,
      summary: {
        'Total sessions': '${filtered.length}',
        'Total hours': '${totalHours.toStringAsFixed(1)} hrs',
        'Total wages': 'USD ${totalWages.toStringAsFixed(2)}',
      },
      generatedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static String _weatherLabel(String? w) {
    switch (w) {
      case 'hot_dry':  return 'Hot & Dry';
      case 'mild':     return 'Mild';
      case 'cool':     return 'Cool';
      case 'rainy':    return 'Rainy';
      default:         return '—';
    }
  }

  static String _capitalise(String s) =>
      s.isEmpty
          ? s
          : s[0].toUpperCase() + s.substring(1);

  static String formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}