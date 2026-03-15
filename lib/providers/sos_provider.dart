// lib/providers/sos_provider.dart
// Developed by Sir Enocks — Cor Technologies

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/sos_model.dart';
import '../models/farm_management_model.dart';
import '../services/sos_database_service.dart';

enum SosProviderState { idle, loading, success, error }

class SosProvider extends ChangeNotifier {
  SosProviderState _state = SosProviderState.idle;
  String _errorMessage = '';
  SosProviderState get state => _state;
  String get errorMessage => _errorMessage;

  List<SosAlert> _alerts = [];
  List<SosAlert> _workerAlerts = [];

  List<SosAlert> get alerts => _alerts;
  List<SosAlert> get workerAlerts => _workerAlerts;

  List<SosAlert> get activeAlerts =>
      _alerts.where((a) => a.status == SosStatus.active).toList();
  List<SosAlert> get acknowledgedAlerts =>
      _alerts.where((a) => a.status == SosStatus.acknowledged).toList();
  List<SosAlert> get resolvedAlerts =>
      _alerts.where((a) => a.status == SosStatus.resolved).toList();
  int get activeCount =>
      _alerts.where((a) => a.status == SosStatus.active).length;

  Future<void> loadAlerts(String farmId) async {
    _alerts = await SosDatabaseService.getAlertsByFarm(farmId);
    notifyListeners();
  }

  Future<void> loadWorkerAlerts(String workerId) async {
    _workerAlerts = await SosDatabaseService.getAlertsByWorker(workerId);
    notifyListeners();
  }

  Future<bool> triggerSos({
    required WorkerModel worker,
    required FarmEntity farm,
    required SosType type,
    required String message,
  }) async {
    _setState(SosProviderState.loading);
    try {
      double lat = farm.latitude;
      double lng = farm.longitude;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.whileInUse ||
              perm == LocationPermission.always) {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            );
            lat = pos.latitude;
            lng = pos.longitude;
          }
        }
      } catch (_) {}

      final alert = SosAlert(
        id: _generateId(),
        farmId: farm.id,
        farmCode: farm.farmCode,
        workerId: worker.id,
        workerName: worker.fullName,
        workerPhone: worker.phone,
        type: type,
        message: message.trim(),
        latitude: lat,
        longitude: lng,
        status: SosStatus.active,
        triggeredAt: DateTime.now(),
      );

      await SosDatabaseService.insertAlert(alert);
      _alerts.insert(0, alert);
      _workerAlerts.insert(0, alert);
      _setState(SosProviderState.success);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(SosProviderState.error);
      return false;
    }
  }

  Future<void> acknowledgeAlert({
    required String alertId,
    required String acknowledgedByName,
  }) async {
    await SosDatabaseService.acknowledgeAlert(
      alertId: alertId,
      acknowledgedByName: acknowledgedByName,
    );
    _updateLocal(alertId, SosStatus.acknowledged,
        acknowledgedByName: acknowledgedByName,
        acknowledgedAt: DateTime.now());
  }

  Future<void> resolveAlert({
    required String alertId,
    required String resolutionNote,
  }) async {
    await SosDatabaseService.resolveAlert(
      alertId: alertId,
      resolutionNote: resolutionNote,
    );
    _updateLocal(alertId, SosStatus.resolved,
        resolvedAt: DateTime.now(), resolutionNote: resolutionNote);
  }

  void _updateLocal(
    String alertId,
    SosStatus newStatus, {
    String? acknowledgedByName,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    String? resolutionNote,
  }) {
    for (final list in [_alerts, _workerAlerts]) {
      final idx = list.indexWhere((a) => a.id == alertId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          status: newStatus,
          acknowledgedByName: acknowledgedByName,
          acknowledgedAt: acknowledgedAt,
          resolvedAt: resolvedAt,
          resolutionNote: resolutionNote,
        );
      }
    }
    notifyListeners();
  }

  void _setState(SosProviderState s) {
    _state = s;
    notifyListeners();
  }

  void resetState() {
    _state = SosProviderState.idle;
    _errorMessage = '';
    notifyListeners();
  }

  String _generateId() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256))
        .map((v) => v.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}