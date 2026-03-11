// lib/models/farm_management_model.dart
// Developed by Sir Enocks — Cor Technologies
// Data models for Phase 2: Farm Registration, Worker Onboarding, GPS Clock-In

// ---------------------------------------------------------------------------
// FARM ENTITY
// A registered farm with GPS location and a generated Farm Code
// ---------------------------------------------------------------------------
class FarmEntity {
  final String id;
  final String ownerId;       // UserModel.userId of the owner
  final String farmCode;      // e.g. FARM-4821 — shared with workers
  final String farmName;
  final double latitude;
  final double longitude;
  final double sizeHectares;
  final double geofenceRadiusMeters; // default 500m
  final List<String> cropTypes;
  final List<String> livestockTypes;
  final String district;
  final String province;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FarmEntity({
    required this.id,
    required this.ownerId,
    required this.farmCode,
    required this.farmName,
    required this.latitude,
    required this.longitude,
    required this.sizeHectares,
    this.geofenceRadiusMeters = 500,
    required this.cropTypes,
    required this.livestockTypes,
    required this.district,
    required this.province,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'owner_id': ownerId,
        'farm_code': farmCode,
        'farm_name': farmName,
        'latitude': latitude,
        'longitude': longitude,
        'size_hectares': sizeHectares,
        'geofence_radius_meters': geofenceRadiusMeters,
        'crop_types': cropTypes.join(','),
        'livestock_types': livestockTypes.join(','),
        'district': district,
        'province': province,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory FarmEntity.fromMap(Map<String, dynamic> m) => FarmEntity(
        id: m['id'],
        ownerId: m['owner_id'],
        farmCode: m['farm_code'],
        farmName: m['farm_name'],
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        sizeHectares: (m['size_hectares'] as num).toDouble(),
        geofenceRadiusMeters:
            (m['geofence_radius_meters'] as num?)?.toDouble() ?? 500,
        cropTypes: (m['crop_types'] as String)
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
        livestockTypes: (m['livestock_types'] as String)
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
        district: m['district'],
        province: m['province'],
        createdAt: DateTime.parse(m['created_at']),
        updatedAt: DateTime.parse(m['updated_at']),
      );

  FarmEntity copyWith({double? geofenceRadiusMeters}) => FarmEntity(
        id: id,
        ownerId: ownerId,
        farmCode: farmCode,
        farmName: farmName,
        latitude: latitude,
        longitude: longitude,
        sizeHectares: sizeHectares,
        geofenceRadiusMeters:
            geofenceRadiusMeters ?? this.geofenceRadiusMeters,
        cropTypes: cropTypes,
        livestockTypes: livestockTypes,
        district: district,
        province: province,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

// ---------------------------------------------------------------------------
// WORKER MODEL
// A worker linked to a farm via Farm Code
// ---------------------------------------------------------------------------
enum WorkerRole { fieldWorker, supervisor }
enum WorkerStatus { pending, approved, rejected }

class WorkerModel {
  final String id;
  final String farmId;        // FarmEntity.id
  final String farmCode;      // The code they joined with
  final String ownerId;       // Farm owner's userId
  final String fullName;
  final String phone;
  final String pin;           // 4-digit PIN hashed
  final WorkerRole role;
  final WorkerStatus status;
  final DateTime joinedAt;
  final DateTime? approvedAt;

  const WorkerModel({
    required this.id,
    required this.farmId,
    required this.farmCode,
    required this.ownerId,
    required this.fullName,
    required this.phone,
    required this.pin,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.approvedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'farm_id': farmId,
        'farm_code': farmCode,
        'owner_id': ownerId,
        'full_name': fullName,
        'phone': phone,
        'pin': pin,
        'role': role.name,
        'status': status.name,
        'joined_at': joinedAt.toIso8601String(),
        'approved_at': approvedAt?.toIso8601String(),
      };

  factory WorkerModel.fromMap(Map<String, dynamic> m) => WorkerModel(
        id: m['id'],
        farmId: m['farm_id'],
        farmCode: m['farm_code'],
        ownerId: m['owner_id'],
        fullName: m['full_name'],
        phone: m['phone'],
        pin: m['pin'],
        role: WorkerRole.values.firstWhere(
          (r) => r.name == m['role'],
          orElse: () => WorkerRole.fieldWorker,
        ),
        status: WorkerStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => WorkerStatus.pending,
        ),
        joinedAt: DateTime.parse(m['joined_at']),
        approvedAt: m['approved_at'] != null
            ? DateTime.parse(m['approved_at'])
            : null,
      );

  bool get isApproved => status == WorkerStatus.approved;
}

// ---------------------------------------------------------------------------
// CLOCK RECORD
// GPS clock-in / clock-out record for a worker
// ---------------------------------------------------------------------------
enum ClockStatus { clockedIn, clockedOut }

class ClockRecord {
  final String id;
  final String workerId;      // WorkerModel.id
  final String farmId;
  final String workerName;
  final double clockInLat;
  final double clockInLng;
  final bool withinGeofence;  // Was worker inside farm boundary?
  final DateTime clockInTime;
  final double? clockOutLat;
  final double? clockOutLng;
  final DateTime? clockOutTime;
  final double? hoursWorked;
  final ClockStatus status;

  const ClockRecord({
    required this.id,
    required this.workerId,
    required this.farmId,
    required this.workerName,
    required this.clockInLat,
    required this.clockInLng,
    required this.withinGeofence,
    required this.clockInTime,
    this.clockOutLat,
    this.clockOutLng,
    this.clockOutTime,
    this.hoursWorked,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'worker_id': workerId,
        'farm_id': farmId,
        'worker_name': workerName,
        'clock_in_lat': clockInLat,
        'clock_in_lng': clockInLng,
        'within_geofence': withinGeofence ? 1 : 0,
        'clock_in_time': clockInTime.toIso8601String(),
        'clock_out_lat': clockOutLat,
        'clock_out_lng': clockOutLng,
        'clock_out_time': clockOutTime?.toIso8601String(),
        'hours_worked': hoursWorked,
        'status': status.name,
      };

  factory ClockRecord.fromMap(Map<String, dynamic> m) => ClockRecord(
        id: m['id'],
        workerId: m['worker_id'],
        farmId: m['farm_id'],
        workerName: m['worker_name'],
        clockInLat: (m['clock_in_lat'] as num).toDouble(),
        clockInLng: (m['clock_in_lng'] as num).toDouble(),
        withinGeofence: m['within_geofence'] == 1,
        clockInTime: DateTime.parse(m['clock_in_time']),
        clockOutLat: m['clock_out_lat'] != null
            ? (m['clock_out_lat'] as num).toDouble()
            : null,
        clockOutLng: m['clock_out_lng'] != null
            ? (m['clock_out_lng'] as num).toDouble()
            : null,
        clockOutTime: m['clock_out_time'] != null
            ? DateTime.parse(m['clock_out_time'])
            : null,
        hoursWorked: m['hours_worked'] != null
            ? (m['hours_worked'] as num).toDouble()
            : null,
        status: ClockStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => ClockStatus.clockedOut,
        ),
      );

  bool get isClockedIn => status == ClockStatus.clockedIn;
}