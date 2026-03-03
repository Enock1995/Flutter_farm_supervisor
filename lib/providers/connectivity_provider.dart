// lib/providers/connectivity_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = false;
  Timer? _timer;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _checkNow();
    // Re-check every 15 seconds
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkNow(),
    );
  }

  Future<void> _checkNow() async {
    final online = await ConnectivityService.isOnline();
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  /// Call this manually to force a recheck (e.g. on pull-to-refresh)
  Future<void> recheck() async => _checkNow();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}