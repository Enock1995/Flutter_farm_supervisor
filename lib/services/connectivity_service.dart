// lib/services/connectivity_service.dart
// Reliable online/offline detection for both Windows and Android.
// Uses HTTP HEAD request instead of DNS lookup — works on all platforms.
// Developed by Sir Enocks — Cor Technologies

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static Future<bool> isOnline() async {
    // Try multiple endpoints — if any responds, we're online
    final endpoints = [
      'https://www.google.com',
      'https://dns.google',
      'https://api.openweathermap.org',
    ];

    for (final url in endpoints) {
      try {
        final response = await http
            .head(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        if (response.statusCode < 500) return true;
      } catch (_) {
        continue;
      }
    }
    return false;
  }
}