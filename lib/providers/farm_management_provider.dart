// lib/providers/farm_management_provider.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import '../models/farm_management_model.dart';
import '../models/task_activity_model.dart';
import '../services/farm_management_database_service.dart';
import '../services/task_activity_database_service.dart';

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
    _farms =
        await FarmManagementDatabaseService.getFarmsByOwner(ownerId);
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
    _setState(FarmMgmtState.loading);

    try {
      final now = DateTime.now();
      final farm = FarmEntity(
        id: _generateId(),
        ownerId: ownerId,
        farmCode:
            FarmManagementDatabaseService.generateFarmCode(),
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

      // Log activity
      await _log(
        farmId: saved.id,
        ownerId: ownerId,
        type: ActivityType.farmRegistered,
        actorName: 'You',
        title: '${saved.farmName} registered',
        detail: 'Farm code: ${saved.farmCode}',
        referenceId: saved.id,
      );

      _setState(FarmMgmtState.success);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(FarmMgmtState.error);
      return false;
    }
  }

  Future<void> updateGeofenceRadius(
      String farmId, double meters) async {
    await FarmManagementDatabaseService.updateGeofence(
        farmId, meters);
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

  Future<WorkerJoinResult> joinFarm({
    required String farmCode,
    required String fullName,
    required String phone,
    required String pin,
    WorkerRole role = WorkerRole.fieldWorker,
  }) async {
    _setState(FarmMgmtState.loading);

    try {
      final farm = await FarmManagementDatabaseService
          .getFarmByCode(farmCode.trim().toUpperCase());
      if (farm == null) {
        _errorMessage =
            'Farm code not found. Please check and try again.';
        _setState(FarmMgmtState.error);
        return WorkerJoinResult.notFound;
      }

      final alreadyRegistered = await FarmManagementDatabaseService
          .isPhoneRegisteredOnFarm(
              phone, farmCode.toUpperCase());
      if (alreadyRegistered) {
        _errorMessage =
            'This phone number is already registered on this farm.';
        _setState(FarmMgmtState.error);
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

      await _log(
        farmId: farm.id,
        ownerId: farm.ownerId,
        type: ActivityType.workerJoined,
        actorName: fullName.trim(),
        title: '${fullName.trim()} requested to join',
        detail: 'Pending approval',
        referenceId: worker.id,
      );

      _setState(FarmMgmtState.success);
      return WorkerJoinResult.pendingApproval;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(FarmMgmtState.error);
      return WorkerJoinResult.error;
    }
  }

  Future<void> updateWorkerStatus(
      String workerId, WorkerStatus status) async {
    await FarmManagementDatabaseService.updateWorkerStatus(
        workerId, status);

    final w = _pendingWorkers.firstWhere((w) => w.id == workerId,
        orElse: () => _workers.firstWhere((w) => w.id == workerId,
            orElse: () => _workers.first));

    if (status == WorkerStatus.approved && _selectedFarm != null) {
      await _log(
        farmId: _selectedFarm!.id,
        ownerId: _selectedFarm!.ownerId,
        type: ActivityType.workerApproved,
        actorName: 'You',
        title: '${w.fullName} approved',
        detail: 'Worker can now clock in',
        referenceId: workerId,
      );
    }

    _pendingWorkers.removeWhere((w) => w.id == workerId);
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

  Future<WorkerLoginResult> workerLogin({
    required String phone,
    required String farmCode,
    required String pin,
  }) async {
    _setState(FarmMgmtState.loading);

    try {
      final worker = await FarmManagementDatabaseService
          .getWorkerByPhoneAndFarm(
              phone.trim(), farmCode.trim().toUpperCase());

      if (worker == null) {
        _errorMessage =
            'Worker not found. Check your phone number and farm code.';
        _setState(FarmMgmtState.error);
        return WorkerLoginResult.notFound;
      }
      if (worker.status == WorkerStatus.pending) {
        _errorMessage =
            'Your account is pending approval from the farm owner.';
        _setState(FarmMgmtState.error);
        return WorkerLoginResult.pending;
      }
      if (worker.status == WorkerStatus.rejected) {
        _errorMessage = 'Your account has been rejected.';
        _setState(FarmMgmtState.error);
        return WorkerLoginResult.rejected;
      }

      final hashedPin =
          FarmManagementDatabaseService.hashPin(pin.trim());
      if (worker.pin != hashedPin) {
        _errorMessage = 'Incorrect PIN.';
        _setState(FarmMgmtState.error);
        return WorkerLoginResult.wrongPin;
      }

      _currentWorker = worker;
      _setState(FarmMgmtState.success);
      return WorkerLoginResult.success;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(FarmMgmtState.error);
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
    _liveAttendance = await FarmManagementDatabaseService
        .getLiveFarmAttendance(farmId);
    notifyListeners();
  }

  Future<ClockInResult> clockIn(
      WorkerModel worker, FarmEntity farm) async {
    _setState(FarmMgmtState.loading);

    try {
      final position = await _getPosition();
      if (position == null) {
        _errorMessage =
            'Could not get your location. Please enable GPS and try again.';
        _setState(FarmMgmtState.error);
        return ClockInResult.locationFailed;
      }
      _lastKnownPosition = position;

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

      await _log(
        farmId: farm.id,
        ownerId: farm.ownerId,
        type: ActivityType.workerClockedIn,
        actorName: worker.fullName,
        title: '${worker.fullName} clocked in',
        detail: withinGeofence
            ? 'Within geofence ✅'
            : '⚠️ Outside geofence (${distanceMeters.toInt()}m away)',
        referenceId: record.id,
      );

      _setState(FarmMgmtState.success);
      return withinGeofence
          ? ClockInResult.success
          : ClockInResult.outsideGeofence;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(FarmMgmtState.error);
      return ClockInResult.error;
    }
  }

  Future<bool> clockOut() async {
    if (_activeClockRecord == null) return false;
    _setState(FarmMgmtState.loading);

    try {
      final position = await _getPosition();
      final lat =
          position?.latitude ?? _activeClockRecord!.clockInLat;
      final lng =
          position?.longitude ?? _activeClockRecord!.clockInLng;

      await FarmManagementDatabaseService.clockOut(
        recordId: _activeClockRecord!.id,
        lat: lat,
        lng: lng,
      );

      // Load farm to get ownerId for activity log
      final farm = await FarmManagementDatabaseService.getFarmById(
          _activeClockRecord!.farmId);

      if (farm != null) {
        final hours = DateTime.now()
                .difference(_activeClockRecord!.clockInTime)
                .inMinutes /
            60.0;
        await _log(
          farmId: farm.id,
          ownerId: farm.ownerId,
          type: ActivityType.workerClockedOut,
          actorName: _activeClockRecord!.workerName,
          title:
              '${_activeClockRecord!.workerName} clocked out',
          detail:
              '${hours.toStringAsFixed(1)}h worked',
          referenceId: _activeClockRecord!.id,
        );
      }

      _clockHistory =
          await FarmManagementDatabaseService.getClockHistory(
              _activeClockRecord!.workerId);
      _activeClockRecord = null;
      _setState(FarmMgmtState.success);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(FarmMgmtState.error);
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

  // ── TASKS ─────────────────────────────────────────────────
  List<TaskModel> _tasks = [];
  Map<String, int> _taskSummary = {};

  List<TaskModel> get tasks => _tasks;
  Map<String, int> get taskSummary => _taskSummary;

  List<TaskModel> get pendingTasks => _tasks
      .where((t) => t.status == TaskStatus.pending)
      .toList();
  List<TaskModel> get inProgressTasks => _tasks
      .where((t) => t.status == TaskStatus.inProgress)
      .toList();
  List<TaskModel> get completedTasks => _tasks
      .where((t) => t.status == TaskStatus.completed)
      .toList();
  List<TaskModel> get overdueTasks =>
      _tasks.where((t) => t.isOverdue).toList();

  Future<void> loadTasks(String farmId,
      {TaskStatus? filterStatus,
      String? filterWorkerId}) async {
    _tasks = await TaskActivityDatabaseService.getTasksByFarm(
      farmId,
      filterStatus: filterStatus,
      filterWorkerId: filterWorkerId,
    );
    _taskSummary =
        await TaskActivityDatabaseService.getTaskSummary(farmId);
    notifyListeners();
  }

  Future<bool> createTask({
    required String farmId,
    required String ownerId,
    required String ownerName,
    required String title,
    required String description,
    required TaskPriority priority,
    required DateTime dueDate,
    String? assignedWorkerId,
    String? assignedWorkerName,
    String? fieldOrPlot,
  }) async {
    _setState(FarmMgmtState.loading);
    try {
      final task = TaskModel(
        id: _generateId(),
        farmId: farmId,
        ownerId: ownerId,
        assignedWorkerId: assignedWorkerId,
        assignedWorkerName: assignedWorkerName,
        title: title.trim(),
        description: description.trim(),
        priority: priority,
        status: TaskStatus.pending,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        fieldOrPlot: fieldOrPlot?.trim(),
      );

      await TaskActivityDatabaseService.insertTask(task);
      _tasks.insert(0, task);
      _taskSummary['pending'] =
          (_taskSummary['pending'] ?? 0) + 1;

      await _log(
        farmId: farmId,
        ownerId: ownerId,
        type: ActivityType.taskCreated,
        actorName: ownerName,
        title: 'Task created: "${task.title}"',
        detail: assignedWorkerName != null
            ? 'Assigned to $assignedWorkerName · Due ${_shortDate(dueDate)}'
            : 'Unassigned · Due ${_shortDate(dueDate)}',
        referenceId: task.id,
      );

      _setState(FarmMgmtState.success);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(FarmMgmtState.error);
      return false;
    }
  }

  Future<void> updateTaskStatus(
    String taskId,
    TaskStatus newStatus,
    String actorName, {
    String? completionNote,
    required String farmId,
    required String ownerId,
  }) async {
    await TaskActivityDatabaseService.updateTaskStatus(
      taskId,
      newStatus,
      completionNote: completionNote,
    );

    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final old = _tasks[index];
      _tasks[index] = old.copyWith(
        status: newStatus,
        startedAt: newStatus == TaskStatus.inProgress
            ? DateTime.now()
            : old.startedAt,
        completedAt: newStatus == TaskStatus.completed
            ? DateTime.now()
            : old.completedAt,
        completionNote: completionNote ?? old.completionNote,
      );

      // Update summary counts
      _taskSummary[old.status.name] =
          ((_taskSummary[old.status.name] ?? 1) - 1)
              .clamp(0, 9999);
      _taskSummary[newStatus.name] =
          (_taskSummary[newStatus.name] ?? 0) + 1;

      ActivityType actType;
      String logTitle;
      switch (newStatus) {
        case TaskStatus.inProgress:
          actType = ActivityType.taskStarted;
          logTitle = '$actorName started "${old.title}"';
          break;
        case TaskStatus.completed:
          actType = ActivityType.taskCompleted;
          logTitle = '$actorName completed "${old.title}"';
          break;
        case TaskStatus.cancelled:
          actType = ActivityType.taskCancelled;
          logTitle = '"${old.title}" was cancelled';
          break;
        default:
          actType = ActivityType.taskCreated;
          logTitle = '"${old.title}" updated';
      }

      await _log(
        farmId: farmId,
        ownerId: ownerId,
        type: actType,
        actorName: actorName,
        title: logTitle,
        detail: completionNote,
        referenceId: taskId,
      );
    }
    notifyListeners();
  }

  Future<void> deleteTask(
      String taskId, String farmId, String ownerId) async {
    await TaskActivityDatabaseService.deleteTask(taskId);
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _taskSummary[_tasks[index].status.name] =
          ((_taskSummary[_tasks[index].status.name] ?? 1) - 1)
              .clamp(0, 9999);
      _tasks.removeAt(index);
    }
    notifyListeners();
  }

  // ── ACTIVITY FEED ─────────────────────────────────────────
  List<ActivityItem> _activityFeed = [];
  List<ActivityItem> get activityFeed => _activityFeed;

  Future<void> loadActivityFeed(String farmId,
      {ActivityType? filterType}) async {
    _activityFeed = await TaskActivityDatabaseService.getActivityFeed(
      farmId,
      filterType: filterType,
    );
    notifyListeners();
  }

  // ── PRIVATE HELPERS ───────────────────────────────────────

  Future<void> _log({
    required String farmId,
    required String ownerId,
    required ActivityType type,
    required String actorName,
    required String title,
    String? detail,
    String? referenceId,
  }) async {
    final item = ActivityItem(
      id: _generateId(),
      farmId: farmId,
      ownerId: ownerId,
      type: type,
      actorName: actorName,
      title: title,
      detail: detail,
      referenceId: referenceId,
      createdAt: DateTime.now(),
    );
    await TaskActivityDatabaseService.logActivity(item);
    // Prepend to in-memory feed if loaded for same farm
    if (_activityFeed.isNotEmpty &&
        _activityFeed.first.farmId == farmId) {
      _activityFeed.insert(0, item);
    }
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

  String _generateId() {
    final random = Random.secure();
    final values =
        List<int>.generate(16, (_) => random.nextInt(256));
    return values
        .map((v) => v.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String _shortDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  void _setState(FarmMgmtState s) {
    _state = s;
    _errorMessage = s == FarmMgmtState.loading ? '' : _errorMessage;
    notifyListeners();
  }

  void resetState() {
    _state = FarmMgmtState.idle;
    _errorMessage = '';
    notifyListeners();
  }
}

// ── Result enums ──────────────────────────────────────────
enum WorkerJoinResult {
  pendingApproval,
  notFound,
  alreadyRegistered,
  error
}

enum WorkerLoginResult {
  success,
  notFound,
  pending,
  rejected,
  wrongPin,
  error
}

enum ClockInResult {
  success,
  outsideGeofence,
  locationFailed,
  error
}