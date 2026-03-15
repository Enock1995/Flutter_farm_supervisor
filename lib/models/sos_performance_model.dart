// lib/models/sos_performance_model.dart
// Developed by Sir Enocks — Cor Technologies

// ============================================================
// SOS ALERT
// ============================================================

enum SosStatus { active, acknowledged, resolved }

extension SosStatusX on SosStatus {
  String get label {
    switch (this) {
      case SosStatus.active:       return 'Active';
      case SosStatus.acknowledged: return 'Acknowledged';
      case SosStatus.resolved:     return 'Resolved';
    }
  }
  String get emoji {
    switch (this) {
      case SosStatus.active:       return '🚨';
      case SosStatus.acknowledged: return '👀';
      case SosStatus.resolved:     return '✅';
    }
  }
}

enum SosType { medical, security, accident, fire, other }

extension SosTypeX on SosType {
  String get label {
    switch (this) {
      case SosType.medical:  return 'Medical Emergency';
      case SosType.security: return 'Security Threat';
      case SosType.accident: return 'Accident';
      case SosType.fire:     return 'Fire';
      case SosType.other:    return 'Other Emergency';
    }
  }
  String get emoji {
    switch (this) {
      case SosType.medical:  return '🏥';
      case SosType.security: return '🔒';
      case SosType.accident: return '⚠️';
      case SosType.fire:     return '🔥';
      case SosType.other:    return '🆘';
    }
  }
}

class SosAlert {
  final String id;
  final String farmId;
  final String ownerId;
  final String triggeredByWorkerId;
  final String triggeredByName;

  final SosType type;
  final String? message;
  final double? latitude;
  final double? longitude;

  final SosStatus status;
  final String? acknowledgedByName;
  final String? resolutionNote;

  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  const SosAlert({
    required this.id,
    required this.farmId,
    required this.ownerId,
    required this.triggeredByWorkerId,
    required this.triggeredByName,
    required this.type,
    this.message,
    this.latitude,
    this.longitude,
    required this.status,
    this.acknowledgedByName,
    this.resolutionNote,
    required this.triggeredAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'farm_id': farmId,
        'owner_id': ownerId,
        'triggered_by_worker_id': triggeredByWorkerId,
        'triggered_by_name': triggeredByName,
        'type': type.name,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.name,
        'acknowledged_by_name': acknowledgedByName,
        'resolution_note': resolutionNote,
        'triggered_at': triggeredAt.toIso8601String(),
        'acknowledged_at': acknowledgedAt?.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };

  factory SosAlert.fromMap(Map<String, dynamic> m) => SosAlert(
        id: m['id'],
        farmId: m['farm_id'],
        ownerId: m['owner_id'],
        triggeredByWorkerId: m['triggered_by_worker_id'],
        triggeredByName: m['triggered_by_name'],
        type: SosType.values.firstWhere(
            (e) => e.name == m['type'],
            orElse: () => SosType.other),
        message: m['message'],
        latitude: m['latitude'] != null
            ? (m['latitude'] as num).toDouble()
            : null,
        longitude: m['longitude'] != null
            ? (m['longitude'] as num).toDouble()
            : null,
        status: SosStatus.values.firstWhere(
            (e) => e.name == m['status'],
            orElse: () => SosStatus.active),
        acknowledgedByName: m['acknowledged_by_name'],
        resolutionNote: m['resolution_note'],
        triggeredAt: DateTime.parse(m['triggered_at']),
        acknowledgedAt: m['acknowledged_at'] != null
            ? DateTime.parse(m['acknowledged_at'])
            : null,
        resolvedAt: m['resolved_at'] != null
            ? DateTime.parse(m['resolved_at'])
            : null,
      );

  SosAlert copyWith({
    SosStatus? status,
    String? acknowledgedByName,
    String? resolutionNote,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
  }) =>
      SosAlert(
        id: id,
        farmId: farmId,
        ownerId: ownerId,
        triggeredByWorkerId: triggeredByWorkerId,
        triggeredByName: triggeredByName,
        type: type,
        message: message,
        latitude: latitude,
        longitude: longitude,
        status: status ?? this.status,
        acknowledgedByName: acknowledgedByName ?? this.acknowledgedByName,
        resolutionNote: resolutionNote ?? this.resolutionNote,
        triggeredAt: triggeredAt,
        acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
        resolvedAt: resolvedAt ?? this.resolvedAt,
      );

  bool get isActive => status == SosStatus.active;
}

// ============================================================
// WORKER PERFORMANCE SNAPSHOT
// ============================================================

class WorkerPerformanceStats {
  final String workerId;
  final String workerName;
  final String workerPhone;
  final String role;

  // Attendance
  final int daysPresent;
  final int totalDaysInPeriod;
  final double totalHoursWorked;
  final double avgHoursPerDay;
  final int lateClockIns;
  final int outsideGeofenceCount;

  // Tasks
  final int tasksAssigned;
  final int tasksCompleted;
  final int tasksPending;
  final int tasksOverdue;

  // Scores (0–100)
  final double attendanceScore;
  final double taskCompletionRate;
  final double punctualityScore;
  final double overallScore;

  // Sparkline data — weekly hours (8 buckets, oldest→newest)
  final List<double> weeklyHours;

  const WorkerPerformanceStats({
    required this.workerId,
    required this.workerName,
    required this.workerPhone,
    required this.role,
    required this.daysPresent,
    required this.totalDaysInPeriod,
    required this.totalHoursWorked,
    required this.avgHoursPerDay,
    required this.lateClockIns,
    required this.outsideGeofenceCount,
    required this.tasksAssigned,
    required this.tasksCompleted,
    required this.tasksPending,
    required this.tasksOverdue,
    required this.attendanceScore,
    required this.taskCompletionRate,
    required this.punctualityScore,
    required this.overallScore,
    required this.weeklyHours,
  });

  factory WorkerPerformanceStats.fromRaw({
    required String workerId,
    required String workerName,
    required String workerPhone,
    required String role,
    required List<Map<String, dynamic>> clockRows,
    required int tasksAssigned,
    required int tasksCompleted,
    required int tasksPending,
    required int tasksOverdue,
    required DateTime from,
    required DateTime to,
  }) {
    final totalDays = to.difference(from).inDays + 1;
    final daySet = <String>{};
    double totalHours = 0;
    int lateIns = 0;
    int outsideGeo = 0;
    final weekBuckets = List<double>.filled(8, 0.0);

    for (final row in clockRows) {
      final clockIn = DateTime.parse(row['clock_in_time'] as String);
      final dayKey = '${clockIn.year}-${clockIn.month}-${clockIn.day}';
      daySet.add(dayKey);

      final hours = (row['hours_worked'] as num?)?.toDouble() ?? 0.0;
      totalHours += hours;

      if (clockIn.hour > 7 || (clockIn.hour == 7 && clockIn.minute > 30)) {
        lateIns++;
      }
      if ((row['within_geofence'] as int? ?? 1) == 0) outsideGeo++;

      final weeksAgo =
          (to.difference(clockIn).inDays / 7).floor().clamp(0, 7);
      weekBuckets[7 - weeksAgo] += hours;
    }

    final daysPresent = daySet.length;
    final avgHours = daysPresent > 0 ? totalHours / daysPresent : 0.0;
    final attendance =
        totalDays > 0 ? (daysPresent / totalDays * 100).clamp(0.0, 100.0) : 0.0;
    final taskRate = tasksAssigned > 0
        ? (tasksCompleted / tasksAssigned * 100).clamp(0.0, 100.0)
        : 100.0;
    final punctuality = daysPresent > 0
        ? ((daysPresent - lateIns) / daysPresent * 100).clamp(0.0, 100.0)
        : 100.0;
    final overall =
        (attendance * 0.4 + taskRate * 0.35 + punctuality * 0.25)
            .clamp(0.0, 100.0);

    return WorkerPerformanceStats(
      workerId: workerId,
      workerName: workerName,
      workerPhone: workerPhone,
      role: role,
      daysPresent: daysPresent,
      totalDaysInPeriod: totalDays,
      totalHoursWorked: totalHours,
      avgHoursPerDay: avgHours,
      lateClockIns: lateIns,
      outsideGeofenceCount: outsideGeo,
      tasksAssigned: tasksAssigned,
      tasksCompleted: tasksCompleted,
      tasksPending: tasksPending,
      tasksOverdue: tasksOverdue,
      attendanceScore: attendance,
      taskCompletionRate: taskRate,
      punctualityScore: punctuality,
      overallScore: overall,
      weeklyHours: weekBuckets,
    );
  }

  String get grade {
    if (overallScore >= 85) return 'A';
    if (overallScore >= 70) return 'B';
    if (overallScore >= 55) return 'C';
    if (overallScore >= 40) return 'D';
    return 'F';
  }

  String get gradeLabel {
    switch (grade) {
      case 'A': return 'Excellent';
      case 'B': return 'Good';
      case 'C': return 'Average';
      case 'D': return 'Below Average';
      default:  return 'Poor';
    }
  }
}

// ============================================================
// ANALYTICS SNAPSHOT — farm-wide
// ============================================================

class FarmAnalyticsSnapshot {
  // Finance
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;

  // Labour
  final double totalLabourCostUsd;
  final double totalHoursAllWorkers;
  final int totalWorkers;

  // Tasks
  final int totalTasksCreated;
  final int totalTasksCompleted;
  final double taskCompletionRate;

  // Monthly series (last 6 months) for charts
  final List<MonthlyFinanceSummary> monthlyFinance;
  final List<MonthlyLabourSummary> monthlyLabour;

  // Crop breakdown
  final List<CropRevenueStat> cropRevenue;

  const FarmAnalyticsSnapshot({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalLabourCostUsd,
    required this.totalHoursAllWorkers,
    required this.totalWorkers,
    required this.totalTasksCreated,
    required this.totalTasksCompleted,
    required this.taskCompletionRate,
    required this.monthlyFinance,
    required this.monthlyLabour,
    required this.cropRevenue,
  });
}

class MonthlyFinanceSummary {
  final String monthLabel; // e.g. 'Jan', 'Feb'
  final double revenue;
  final double expenses;
  double get profit => revenue - expenses;
  const MonthlyFinanceSummary({
    required this.monthLabel,
    required this.revenue,
    required this.expenses,
  });
}

class MonthlyLabourSummary {
  final String monthLabel;
  final double hours;
  final double costUsd;
  const MonthlyLabourSummary({
    required this.monthLabel,
    required this.hours,
    required this.costUsd,
  });
}

class CropRevenueStat {
  final String cropName;
  final double revenue;
  const CropRevenueStat({required this.cropName, required this.revenue});
}