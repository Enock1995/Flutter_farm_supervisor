// lib/models/payroll_fieldreport_model.dart
// Developed by Sir Enocks — Cor Technologies

// ============================================================
// PAYROLL
// ============================================================

enum PayrollStatus { pending, paid, failed }

extension PayrollStatusX on PayrollStatus {
  String get label {
    switch (this) {
      case PayrollStatus.pending: return 'Pending';
      case PayrollStatus.paid:    return 'Paid';
      case PayrollStatus.failed:  return 'Failed';
    }
  }
  String get emoji {
    switch (this) {
      case PayrollStatus.pending: return '⏳';
      case PayrollStatus.paid:    return '✅';
      case PayrollStatus.failed:  return '❌';
    }
  }
}

class PayrollRecord {
  final String id;
  final String farmId;
  final String ownerId;
  final String workerId;
  final String workerName;
  final String workerPhone;  // EcoCash number

  final double hoursWorked;
  final double hourlyRateUsd;
  final double totalAmountUsd;

  final PayrollStatus status;
  final String? paynowPollUrl;
  final String? paynowReference;
  final String? failureReason;

  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime createdAt;
  final DateTime? paidAt;

  const PayrollRecord({
    required this.id,
    required this.farmId,
    required this.ownerId,
    required this.workerId,
    required this.workerName,
    required this.workerPhone,
    required this.hoursWorked,
    required this.hourlyRateUsd,
    required this.totalAmountUsd,
    required this.status,
    this.paynowPollUrl,
    this.paynowReference,
    this.failureReason,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
    this.paidAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'farm_id': farmId,
        'owner_id': ownerId,
        'worker_id': workerId,
        'worker_name': workerName,
        'worker_phone': workerPhone,
        'hours_worked': hoursWorked,
        'hourly_rate_usd': hourlyRateUsd,
        'total_amount_usd': totalAmountUsd,
        'status': status.name,
        'paynow_poll_url': paynowPollUrl,
        'paynow_reference': paynowReference,
        'failure_reason': failureReason,
        'period_start': periodStart.toIso8601String(),
        'period_end': periodEnd.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'paid_at': paidAt?.toIso8601String(),
      };

  factory PayrollRecord.fromMap(Map<String, dynamic> m) =>
      PayrollRecord(
        id: m['id'],
        farmId: m['farm_id'],
        ownerId: m['owner_id'],
        workerId: m['worker_id'],
        workerName: m['worker_name'],
        workerPhone: m['worker_phone'],
        hoursWorked: (m['hours_worked'] as num).toDouble(),
        hourlyRateUsd: (m['hourly_rate_usd'] as num).toDouble(),
        totalAmountUsd: (m['total_amount_usd'] as num).toDouble(),
        status: PayrollStatus.values.firstWhere(
            (e) => e.name == m['status'],
            orElse: () => PayrollStatus.pending),
        paynowPollUrl: m['paynow_poll_url'],
        paynowReference: m['paynow_reference'],
        failureReason: m['failure_reason'],
        periodStart: DateTime.parse(m['period_start']),
        periodEnd: DateTime.parse(m['period_end']),
        createdAt: DateTime.parse(m['created_at']),
        paidAt:
            m['paid_at'] != null ? DateTime.parse(m['paid_at']) : null,
      );

  PayrollRecord copyWith({
    PayrollStatus? status,
    String? paynowPollUrl,
    String? paynowReference,
    String? failureReason,
    DateTime? paidAt,
  }) =>
      PayrollRecord(
        id: id,
        farmId: farmId,
        ownerId: ownerId,
        workerId: workerId,
        workerName: workerName,
        workerPhone: workerPhone,
        hoursWorked: hoursWorked,
        hourlyRateUsd: hourlyRateUsd,
        totalAmountUsd: totalAmountUsd,
        status: status ?? this.status,
        paynowPollUrl: paynowPollUrl ?? this.paynowPollUrl,
        paynowReference: paynowReference ?? this.paynowReference,
        failureReason: failureReason ?? this.failureReason,
        periodStart: periodStart,
        periodEnd: periodEnd,
        createdAt: createdAt,
        paidAt: paidAt ?? this.paidAt,
      );
}

// ============================================================
// FIELD REPORT
// ============================================================

enum FieldReportCategory {
  generalUpdate,
  pestDisease,
  weatherDamage,
  irrigation,
  harvest,
  livestock,
  other,
}

extension FieldReportCategoryX on FieldReportCategory {
  String get label {
    switch (this) {
      case FieldReportCategory.generalUpdate: return 'General Update';
      case FieldReportCategory.pestDisease:   return 'Pest / Disease';
      case FieldReportCategory.weatherDamage: return 'Weather Damage';
      case FieldReportCategory.irrigation:    return 'Irrigation';
      case FieldReportCategory.harvest:       return 'Harvest';
      case FieldReportCategory.livestock:     return 'Livestock';
      case FieldReportCategory.other:         return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case FieldReportCategory.generalUpdate: return '📋';
      case FieldReportCategory.pestDisease:   return '🐛';
      case FieldReportCategory.weatherDamage: return '🌩️';
      case FieldReportCategory.irrigation:    return '💧';
      case FieldReportCategory.harvest:       return '🌾';
      case FieldReportCategory.livestock:     return '🐄';
      case FieldReportCategory.other:         return '📝';
    }
  }
}

class FieldReport {
  final String id;
  final String farmId;
  final String ownerId;
  final String reportedByWorkerId;
  final String reportedByName;

  final FieldReportCategory category;
  final String title;
  final String body;
  final String? fieldOrPlot;

  final bool requiresOwnerAttention;
  final bool ownerViewed;

  final DateTime createdAt;
  final DateTime? viewedAt;

  const FieldReport({
    required this.id,
    required this.farmId,
    required this.ownerId,
    required this.reportedByWorkerId,
    required this.reportedByName,
    required this.category,
    required this.title,
    required this.body,
    this.fieldOrPlot,
    this.requiresOwnerAttention = false,
    this.ownerViewed = false,
    required this.createdAt,
    this.viewedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'farm_id': farmId,
        'owner_id': ownerId,
        'reported_by_worker_id': reportedByWorkerId,
        'reported_by_name': reportedByName,
        'category': category.name,
        'title': title,
        'body': body,
        'field_or_plot': fieldOrPlot,
        'requires_owner_attention': requiresOwnerAttention ? 1 : 0,
        'owner_viewed': ownerViewed ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'viewed_at': viewedAt?.toIso8601String(),
      };

  factory FieldReport.fromMap(Map<String, dynamic> m) => FieldReport(
        id: m['id'],
        farmId: m['farm_id'],
        ownerId: m['owner_id'],
        reportedByWorkerId: m['reported_by_worker_id'],
        reportedByName: m['reported_by_name'],
        category: FieldReportCategory.values.firstWhere(
            (e) => e.name == m['category'],
            orElse: () => FieldReportCategory.generalUpdate),
        title: m['title'],
        body: m['body'],
        fieldOrPlot: m['field_or_plot'],
        requiresOwnerAttention: m['requires_owner_attention'] == 1,
        ownerViewed: m['owner_viewed'] == 1,
        createdAt: DateTime.parse(m['created_at']),
        viewedAt: m['viewed_at'] != null
            ? DateTime.parse(m['viewed_at'])
            : null,
      );

  FieldReport copyWith({bool? ownerViewed, DateTime? viewedAt}) =>
      FieldReport(
        id: id,
        farmId: farmId,
        ownerId: ownerId,
        reportedByWorkerId: reportedByWorkerId,
        reportedByName: reportedByName,
        category: category,
        title: title,
        body: body,
        fieldOrPlot: fieldOrPlot,
        requiresOwnerAttention: requiresOwnerAttention,
        ownerViewed: ownerViewed ?? this.ownerViewed,
        createdAt: createdAt,
        viewedAt: viewedAt ?? this.viewedAt,
      );
}

// ============================================================
// PHOTO DIARY
// ============================================================

enum PhotoDiaryCategory {
  cropProgress,
  pestDisease,
  harvest,
  infrastructure,
  livestock,
  weather,
  general,
}

extension PhotoDiaryCategoryX on PhotoDiaryCategory {
  String get label {
    switch (this) {
      case PhotoDiaryCategory.cropProgress:   return 'Crop Progress';
      case PhotoDiaryCategory.pestDisease:    return 'Pest / Disease';
      case PhotoDiaryCategory.harvest:        return 'Harvest';
      case PhotoDiaryCategory.infrastructure: return 'Infrastructure';
      case PhotoDiaryCategory.livestock:      return 'Livestock';
      case PhotoDiaryCategory.weather:        return 'Weather';
      case PhotoDiaryCategory.general:        return 'General';
    }
  }

  String get emoji {
    switch (this) {
      case PhotoDiaryCategory.cropProgress:   return '🌱';
      case PhotoDiaryCategory.pestDisease:    return '🐛';
      case PhotoDiaryCategory.harvest:        return '🌾';
      case PhotoDiaryCategory.infrastructure: return '🏗️';
      case PhotoDiaryCategory.livestock:      return '🐄';
      case PhotoDiaryCategory.weather:        return '🌩️';
      case PhotoDiaryCategory.general:        return '📷';
    }
  }
}

class PhotoEntry {
  final String id;
  final String farmId;
  final String ownerId;
  final String takenByWorkerId;
  final String takenByName;

  final PhotoDiaryCategory category;
  final String caption;
  final String? fieldOrPlot;
  final String imagePath;  // Local file path on device

  final DateTime takenAt;

  const PhotoEntry({
    required this.id,
    required this.farmId,
    required this.ownerId,
    required this.takenByWorkerId,
    required this.takenByName,
    required this.category,
    required this.caption,
    this.fieldOrPlot,
    required this.imagePath,
    required this.takenAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'farm_id': farmId,
        'owner_id': ownerId,
        'taken_by_worker_id': takenByWorkerId,
        'taken_by_name': takenByName,
        'category': category.name,
        'caption': caption,
        'field_or_plot': fieldOrPlot,
        'image_path': imagePath,
        'taken_at': takenAt.toIso8601String(),
      };

  factory PhotoEntry.fromMap(Map<String, dynamic> m) => PhotoEntry(
        id: m['id'],
        farmId: m['farm_id'],
        ownerId: m['owner_id'],
        takenByWorkerId: m['taken_by_worker_id'],
        takenByName: m['taken_by_name'],
        category: PhotoDiaryCategory.values.firstWhere(
            (e) => e.name == m['category'],
            orElse: () => PhotoDiaryCategory.general),
        caption: m['caption'],
        fieldOrPlot: m['field_or_plot'],
        imagePath: m['image_path'],
        takenAt: DateTime.parse(m['taken_at']),
      );
}