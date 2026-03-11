// lib/providers/farm_management_provider.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/farm_management_model.dart';
import '../services/farm_management_database_service.dart';

enum FarmMgmtState { idle, loading, success, error }

class FarmManagementProvider extends ChangeNotifier {
  // ── Shared state ──────────────────────────────────────────
  FarmMgmtState _state = FarmMgmtState.idle;
  String _errorMessage = '';
  FarmMgmtState get state => _state;
  String get errorMessage => _errorMessage;

  // ── Farms ─────────────────────────────────────────────────
  List<FarmEntity> _farms = [];
  FarmEntity? _selectedFarm;
  List<FarmEntity> get farms => _farms;
  FarmEntity? get selectedFarm => _selectedFarm;

  Future<void> loadFarms(String ownerId) async {
    _farms = await FarmManagementDatabaseService.getFarmsByOwner(ownerId);
    if (_farms.isNotEmpty) _selectedFarm ??= _farms.first;
    notifyListeners();
  }

  void selectFarm(FarmEntity farm) {
    _selectedFarm = farm;
    notifyListeners();
  }

  Future<bool> registerFarm({
    required String ownerId,
    required String farmName,
    required double latitude,
    required double longitude,
    required double sizeHectares,
    required List<String> cropTypes,
    required List<String> livestockTypes,
    required String district,
    required String province,
    double geofenceRadius = 500,
  }) async {
    _state = FarmMgmtState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final now = DateTime.now();
      final farm = FarmEntity(
        id: _generateId(),
        ownerId: ownerId,
        farmCode: FarmManagementDatabaseService.generateFarmCode(),
        farmName: farmName.trim(),
        latitude: latitude,
        longitude: longitude,
        sizeHectares: sizeHectares,
        geofenceRadiusMeters: geofenceRadius,
        cropTypes: cropTypes,
        livestockTypes: livestockTypes,
        district: district.trim(),
        province: province.trim(),
        createdAt: now,
        updatedAt: now,
      );

      final saved =
          await FarmManagementDatabaseService.saveFarm(farm);
      _farms.insert(0, saved);
      _selectedFarm = saved;
      _state = FarmMgmtState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = FarmMgmtState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateGeofenceRadius(
      String farmId, double meters) async {
    await FarmManagementDatabaseService.updateGeofence(farmId, meters);
    final index = _farms.indexWhere((f) => f.id == farmId);
    if (index != -1) {
      _farms[index] =
          _farms[index].copyWith(geofenceRadiusMeters: meters);
      if (_selectedFarm?.id == farmId) {
        _selectedFarm =
            _selectedFarm!.copyWith(geofenceRadiusMeters: meters);
      }
    }
    notifyListeners();
  }

  // ── Workers ───────────────────────────────────────────────
  List<WorkerModel> _workers = [];
  List<WorkerModel> _pendingWorkers = [];
  List<WorkerModel> get workers => _workers;
  List<WorkerModel> get pendingWorkers => _pendingWorkers;

  // Worker currently logged in (for worker-side view)
  WorkerModel? _currentWorker;
  WorkerModel? get currentWorker => _currentWorker;

  Future<void> loadWorkers(String farmId) async {
    _workers =
        await FarmManagementDatabaseService.getWorkersByFarm(farmId);
    notifyListeners();
  }

  Future<void> loadPendingWorkers(String ownerId) async {
    _pendingWorkers =
        await FarmManagementDatabaseService.getPendingWorkers(ownerId);
    notifyListeners();
  }

  /// Worker joins a farm using a Farm Code
  Future<WorkerJoinResult> joinFarm({
    required String farmCode,
    required String fullName,
    required String phone,
    required String pin,
    WorkerRole role = WorkerRole.fieldWorker,
  }) async {
    _state = FarmMgmtState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      // Look up farm
      final farm = await FarmManagementDatabaseService.getFarmByCode(
          farmCode.trim().toUpperCase());
      if (farm == null) {
        _state = FarmMgmtState.error;
        _errorMessage = 'Farm code not found. Please check and try again.';
        notifyListeners();
        return WorkerJoinResult.notFound;
      }

      // Check if already registered
      final alreadyRegistered =
          await FarmManagementDatabaseService.isPhoneRegisteredOnFarm(
              phone, farmCode.toUpperCase());
      if (alreadyRegistered) {
        _state = FarmMgmtState.error;
        _errorMessage =
            'This phone number is already registered on this farm.';
        notifyListeners();
        return WorkerJoinResult.alreadyRegistered;
      }

      final hashedPin =
          FarmManagementDatabaseService.hashPin(pin.trim());
      final now = DateTime.now();

      final worker = WorkerModel(
        id: _generateId(),
        farmId: farm.id,
        farmCode: farm.farmCode,
        ownerId: farm.ownerId,
        fullName: fullName.trim(),
        phone: phone.trim(),
        pin: hashedPin,
        role: role,
        status: WorkerStatus.pending,
        joinedAt: now,
      );

      await FarmManagementDatabaseService.registerWorker(worker);

      _state = FarmMgmtState.success;
      notifyListeners();
      return WorkerJoinResult.pendingApproval;
    } catch (e) {
      _errorMessage = e.toString();
      _state = FarmMgmtState.error;
      notifyListeners();
      return WorkerJoinResult.error;
    }
  }

  /// Owner approves or rejects a pending worker
  Future<void> updateWorkerStatus(
      String workerId, WorkerStatus status) async {
    await FarmManagementDatabaseService.updateWorkerStatus(
        workerId, status);
    final index =
        _pendingWorkers.indexWhere((w) => w.id == workerId);
    if (index != -1) {
      _pendingWorkers.removeAt(index);
    }
    // Also update in main workers list if loaded
    final wi = _workers.indexWhere((w) => w.id == workerId);
    if (wi != -1) {
      _workers[wi] = WorkerModel(
        id: _workers[wi].id,
        farmId: _workers[wi].farmId,
        farmCode: _workers[wi].farmCode,
        ownerId: _workers[wi].ownerId,
        fullName: _workers[wi].fullName,
        phone: _workers[wi].phone,
        pin: _workers[wi].pin,
        role: _workers[wi].role,
        status: status,
        joinedAt: _workers[wi].joinedAt,
        approvedAt: status == WorkerStatus.approved
            ? DateTime.now()
            : _workers[wi].approvedAt,
      );
    }
    notifyListeners();
  }

  /// Worker logs in with phone + PIN
  Future<WorkerLoginResult> workerLogin({
    required String phone,
    required String farmCode,
    required String pin,
  }) async {
    _state = FarmMgmtState.loading;
    notifyListeners();

    try {
      final worker =
          await FarmManagementDatabaseService.getWorkerByPhoneAndFarm(
              phone.trim(), farmCode.trim().toUpperCase());

      if (worker == null) {
        _state = FarmMgmtState.error;
        _errorMessage =
            'Worker not found. Check your phone number and farm code.';
        notifyListeners();
        return WorkerLoginResult.notFound;
      }

      if (worker.status == WorkerStatus.pending) {
        _state = FarmMgmtState.error;
        _errorMessage =
            'Your account is pending approval from the farm owner.';
        notifyListeners();
        return WorkerLoginResult.pending;
      }

      if (worker.status == WorkerStatus.rejected) {
        _state = FarmMgmtState.error;
        _errorMessage = 'Your account has been rejected.';
        notifyListeners();
        return WorkerLoginResult.rejected;
      }

      final hashedPin =
          FarmManagementDatabaseService.hashPin(pin.trim());
      if (worker.pin != hashedPin) {
        _state = FarmMgmtState.error;
        _errorMessage = 'Incorrect PIN.';
        notifyListeners();
        return WorkerLoginResult.wrongPin;
      }

      _currentWorker = worker;
      _state = FarmMgmtState.success;
      notifyListeners();
      return WorkerLoginResult.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = FarmMgmtState.error;
      notifyListeners();
      return WorkerLoginResult.error;
    }
  }

  // ── GPS Clock-In/Out ──────────────────────────────────────
  ClockRecord? _activeClockRecord;
  List<ClockRecord> _clockHistory = [];
  List<ClockRecord> _liveAttendance = [];
  Position? _lastKnownPosition;

  ClockRecord? get activeClockRecord => _activeClockRecord;
  List<ClockRecord> get clockHistory => _clockHistory;
  List<ClockRecord> get liveAttendance => _liveAttendance;
  Position? get lastKnownPosition => _lastKnownPosition;

  bool get isClockedIn => _activeClockRecord != null;

  Future<void> loadClockState(String workerId) async {
    _activeClockRecord =
        await FarmManagementDatabaseService.getActiveClockRecord(
            workerId);
    _clockHistory =
        await FarmManagementDatabaseService.getClockHistory(workerId);
    notifyListeners();
  }

  Future<void> loadLiveAttendance(String farmId) async {
    _liveAttendance =
        await FarmManagementDatabaseService.getLiveFarmAttendance(
            farmId);
    notifyListeners();
  }

  Future<ClockInResult> clockIn(
      WorkerModel worker, FarmEntity farm) async {
    _state = FarmMgmtState.loading;
    notifyListeners();

    try {
      final position = await _getPosition();
      if (position == null) {
        _state = FarmMgmtState.error;
        _errorMessage =
            'Could not get your location. Please enable GPS and try again.';
        notifyListeners();
        return ClockInResult.locationFailed;
      }

      _lastKnownPosition = position;

      // Check geofence
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        farm.latitude,
        farm.longitude,
      );
      final withinGeofence =
          distanceMeters <= farm.geofenceRadiusMeters;

      final record = ClockRecord(
        id: _generateId(),
        workerId: worker.id,
        farmId: farm.id,
        workerName: worker.fullName,
        clockInLat: position.latitude,
        clockInLng: position.longitude,
        withinGeofence: withinGeofence,
        clockInTime: DateTime.now(),
        status: ClockStatus.clockedIn,
      );

      await FarmManagementDatabaseService.clockIn(record);
      _activeClockRecord = record;
      _clockHistory.insert(0, record);
      _state = FarmMgmtState.success;
      notifyListeners();

      return withinGeofence
          ? ClockInResult.success
          : ClockInResult.outsideGeofence;
    } catch (e) {
      _errorMessage = e.toString();
      _state = FarmMgmtState.error;
      notifyListeners();
      return ClockInResult.error;
    }
  }

  Future<bool> clockOut() async {
    if (_activeClockRecord == null) return false;
    _state = FarmMgmtState.loading;
    notifyListeners();

    try {
      final position = await _getPosition();
      final lat = position?.latitude ?? _activeClockRecord!.clockInLat;
      final lng = position?.longitude ?? _activeClockRecord!.clockInLng;

      await FarmManagementDatabaseService.clockOut(
        recordId: _activeClockRecord!.id,
        lat: lat,
        lng: lng,
      );

      // Refresh history
      _clockHistory = await FarmManagementDatabaseService.getClockHistory(
          _activeClockRecord!.workerId);
      _activeClockRecord = null;
      _state = FarmMgmtState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = FarmMgmtState.error;
      notifyListeners();
      return false;
    }
  }

  Future<Position?> getCurrentPosition() async {
    final pos = await _getPosition();
    if (pos != null) {
      _lastKnownPosition = pos;
      notifyListeners();
    }
    return pos;
  }

  Future<Position?> _getPosition() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission =
          await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  String _generateId() {
    final random = Random.secure();
    final values =
        List<int>.generate(16, (_) => random.nextInt(256));
    return values
        .map((v) => v.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  void resetState() {
    _state = FarmMgmtState.idle;
    _errorMessage = '';
    notifyListeners();
  }
}

// ── Result enums ──────────────────────────────────────────
enum WorkerJoinResult { pendingApproval, notFound, alreadyRegistered, error }
enum WorkerLoginResult { success, notFound, pending, rejected, wrongPin, error }
enum ClockInResult { success, outsideGeofence, locationFailed, error }