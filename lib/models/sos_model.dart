// lib/models/sos_model.dart
// Developed by Sir Enocks — Cor Technologies

enum SosStatus { active, acknowledged, resolved }

enum SosType {
  medical,
  accident,
  fire,
  security,
  weatherHazard,
  other;

  String get label {
    switch (this) {
      case SosType.medical:       return 'Medical Emergency';
      case SosType.accident:      return 'Accident / Injury';
      case SosType.fire:          return 'Fire';
      case SosType.security:      return 'Security Threat';
      case SosType.weatherHazard: return 'Weather Hazard';
      case SosType.other:         return 'Other Emergency';
    }
  }

  String get emoji {
    switch (this) {
      case SosType.medical:       return '🚑';
      case SosType.accident:      return '🦺';
      case SosType.fire:          return '🔥';
      case SosType.security:      return '🚨';
      case SosType.weatherHazard: return '⛈️';
      case SosType.other:         return '🆘';
    }
  }
}

class SosAlert {
  final String id;
  final String farmId;
  final String farmCode;
  final String workerId;
  final String workerName;
  final String workerPhone;
  final SosType type;
  final String message;
  final double latitude;
  final double longitude;
  final SosStatus status;
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final String? acknowledgedByName;
  final String? resolutionNote;

  const SosAlert({
    required this.id,
    required this.farmId,
    required this.farmCode,
    required this.workerId,
    required this.workerName,
    required this.workerPhone,
    required this.type,
    required this.message,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.triggeredAt,
    this.acknowledgedAt,
    this.resolvedAt,
    this.acknowledgedByName,
    this.resolutionNote,
  });

  SosAlert copyWith({
    SosStatus? status,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    String? acknowledgedByName,
    String? resolutionNote,
  }) {
    return SosAlert(
      id: id,
      farmId: farmId,
      farmCode: farmCode,
      workerId: workerId,
      workerName: workerName,
      workerPhone: workerPhone,
      type: type,
      message: message,
      latitude: latitude,
      longitude: longitude,
      status: status ?? this.status,
      triggeredAt: triggeredAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      acknowledgedByName: acknowledgedByName ?? this.acknowledgedByName,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'farm_id': farmId,
        'farm_code': farmCode,
        'worker_id': workerId,
        'worker_name': workerName,
        'worker_phone': workerPhone,
        'type': type.name,
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.name,
        'triggered_at': triggeredAt.toIso8601String(),
        'acknowledged_at': acknowledgedAt?.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
        'acknowledged_by_name': acknowledgedByName,
        'resolution_note': resolutionNote,
      };

  factory SosAlert.fromMap(Map<String, dynamic> m) => SosAlert(
        id: m['id'] as String,
        farmId: m['farm_id'] as String,
        farmCode: m['farm_code'] as String,
        workerId: m['worker_id'] as String,
        workerName: m['worker_name'] as String,
        workerPhone: m['worker_phone'] as String,
        type: SosType.values.firstWhere(
          (e) => e.name == m['type'],
          orElse: () => SosType.other,
        ),
        message: m['message'] as String,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        status: SosStatus.values.firstWhere(
          (e) => e.name == m['status'],
          orElse: () => SosStatus.active,
        ),
        triggeredAt: DateTime.parse(m['triggered_at'] as String),
        acknowledgedAt: m['acknowledged_at'] != null
            ? DateTime.parse(m['acknowledged_at'] as String)
            : null,
        resolvedAt: m['resolved_at'] != null
            ? DateTime.parse(m['resolved_at'] as String)
            : null,
        acknowledgedByName: m['acknowledged_by_name'] as String?,
        resolutionNote: m['resolution_note'] as String?,
      );
}