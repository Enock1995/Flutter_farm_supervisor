// lib/services/labour_service.dart
// Labour Tracker — worker management, attendance, and pay calculation.
// Developed by Sir Enocks — Cor Technologies

class FarmWorker {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String workerType;   // 'permanent' | 'seasonal' | 'casual'
  final double dailyRateUsd;
  final String? assignedPlot;
  final String? nationalId;
  final bool isActive;
  final DateTime addedAt;

  const FarmWorker({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    this.workerType = 'casual',
    required this.dailyRateUsd,
    this.assignedPlot,
    this.nationalId,
    this.isActive = true,
    required this.addedAt,
  });

  String get typeLabel {
    switch (workerType) {
      case 'permanent': return 'Permanent';
      case 'seasonal':  return 'Seasonal';
      default:          return 'Casual';
    }
  }

  String get typeEmoji {
    switch (workerType) {
      case 'permanent': return '👷';
      case 'seasonal':  return '🌾';
      default:          return '🤝';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'full_name': fullName,
        'phone': phone,
        'worker_type': workerType,
        'daily_rate_usd': dailyRateUsd,
        'assigned_plot': assignedPlot,
        'national_id': nationalId,
        'is_active': isActive ? 1 : 0,
        'added_at': addedAt.toIso8601String(),
      };

  factory FarmWorker.fromMap(Map<String, dynamic> m) => FarmWorker(
        id: m['id'],
        userId: m['user_id'],
        fullName: m['full_name'],
        phone: m['phone'],
        workerType: m['worker_type'] ?? 'casual',
        dailyRateUsd:
            (m['daily_rate_usd'] as num).toDouble(),
        assignedPlot: m['assigned_plot'],
        nationalId: m['national_id'],
        isActive: (m['is_active'] as int? ?? 1) == 1,
        addedAt: DateTime.parse(m['added_at']),
      );

  FarmWorker copyWith({bool? isActive}) => FarmWorker(
        id: id,
        userId: userId,
        fullName: fullName,
        phone: phone,
        workerType: workerType,
        dailyRateUsd: dailyRateUsd,
        assignedPlot: assignedPlot,
        nationalId: nationalId,
        isActive: isActive ?? this.isActive,
        addedAt: addedAt,
      );
}

// ---------------------------------------------------------------------------

class AttendanceRecord {
  final String id;
  final String workerId;
  final String userId;
  final DateTime date;
  final String status;    // 'present' | 'absent' | 'half'
  final String? notes;
  final double hoursWorked; // 8 = full, 4 = half

  const AttendanceRecord({
    required this.id,
    required this.workerId,
    required this.userId,
    required this.date,
    required this.status,
    this.notes,
    this.hoursWorked = 8,
  });

  /// Multiplier for pay: present=1.0, half=0.5, absent=0.0
  double get payMultiplier {
    switch (status) {
      case 'present': return 1.0;
      case 'half':    return 0.5;
      default:        return 0.0;
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'present': return '✅';
      case 'half':    return '🌗';
      default:        return '❌';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'present': return 'Present';
      case 'half':    return 'Half Day';
      default:        return 'Absent';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'worker_id': workerId,
        'user_id': userId,
        'date': date.toIso8601String(),
        'status': status,
        'notes': notes,
        'hours_worked': hoursWorked,
      };

  factory AttendanceRecord.fromMap(
          Map<String, dynamic> m) =>
      AttendanceRecord(
        id: m['id'],
        workerId: m['worker_id'],
        userId: m['user_id'],
        date: DateTime.parse(m['date']),
        status: m['status'] ?? 'absent',
        notes: m['notes'],
        hoursWorked:
            (m['hours_worked'] as num?)?.toDouble() ?? 8,
      );
}

// ---------------------------------------------------------------------------
// PAY SUMMARY
// ---------------------------------------------------------------------------

class WorkerPaySummary {
  final FarmWorker worker;
  final int daysPresent;
  final int daysHalf;
  final int daysAbsent;
  final double totalDaysEquivalent; // present + 0.5*half
  final double totalPayUsd;
  final DateTime periodStart;
  final DateTime periodEnd;

  const WorkerPaySummary({
    required this.worker,
    required this.daysPresent,
    required this.daysHalf,
    required this.daysAbsent,
    required this.totalDaysEquivalent,
    required this.totalPayUsd,
    required this.periodStart,
    required this.periodEnd,
  });
}

// ---------------------------------------------------------------------------
// SERVICE
// ---------------------------------------------------------------------------

class LabourService {
  static const List<String> workerTypes = [
    'casual',
    'seasonal',
    'permanent',
  ];

  /// Calculate pay summary for a worker over a date range.
  static WorkerPaySummary calculatePay({
    required FarmWorker worker,
    required List<AttendanceRecord> attendance,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final periodRecords = attendance.where((a) =>
        !a.date.isBefore(periodStart) &&
        !a.date.isAfter(periodEnd)).toList();

    int present = 0, half = 0, absent = 0;
    for (final r in periodRecords) {
      if (r.status == 'present') present++;
      else if (r.status == 'half') half++;
      else absent++;
    }

    final equivalent = present + (half * 0.5);
    final pay = equivalent * worker.dailyRateUsd;

    return WorkerPaySummary(
      worker: worker,
      daysPresent: present,
      daysHalf: half,
      daysAbsent: absent,
      totalDaysEquivalent: equivalent,
      totalPayUsd: pay,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  /// Get start/end of current week (Mon–Sun)
  static (DateTime, DateTime) currentWeek() {
    final now = DateTime.now();
    final monday =
        now.subtract(Duration(days: now.weekday - 1));
    final start =
        DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 6));
    return (start, end);
  }

  /// Get start/end of current month
  static (DateTime, DateTime) currentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return (start, end);
  }

  /// Suggested daily rates in USD for Zimbabwe context
  static const Map<String, double> suggestedRates = {
    'General labour':    5.0,
    'Skilled (spray)':   8.0,
    'Tractor operator':  12.0,
    'Supervisor':        15.0,
    'Irrigation tech':   10.0,
    'Harvest team':      6.0,
  };
}