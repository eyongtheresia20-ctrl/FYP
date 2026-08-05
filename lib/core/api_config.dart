import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static const String _port = '8080';
  static String _activeHost = '192.168.1.148:$_port';
  static bool _hasTested = false;

  static String get host {
    if (kIsWeb) return 'localhost:$_port';
    return _activeHost;
  }

  static String get baseUrl => 'http://$host/minesec_api/api';
  static String get authUrl => '$baseUrl/auth.php';
  static String get adminUrl => '$baseUrl/admin.php';
  static String get dashboardUrl => '$baseUrl/dashboard.php';
  static String get assessmentUrl => '$baseUrl/assessment.php';

  /// Automatically tests and finds the working host IP for Android (Physical device or Emulator)
  static Future<String> getWorkingHost({bool forceRetest = false}) async {
    if (kIsWeb) return 'localhost:$_port';
    if (_hasTested && !forceRetest) return _activeHost;

    final candidates = [
      '192.168.1.148:$_port', // Physical Android Phone over local Wi-Fi
      '10.0.2.2:$_port',      // Android Emulator -> Host Machine
      '127.0.0.1:$_port',     // Localhost fallback
      'localhost:$_port',
    ];

    for (final candidate in candidates) {
      try {
        final res = await http
            .get(Uri.parse('http://$candidate/minesec_api/api/auth.php?action=check_matricule'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode >= 200 && res.statusCode < 500) {
          _activeHost = candidate;
          _hasTested = true;
          return _activeHost;
        }
      } catch (_) {
        // Try next candidate IP
      }
    }

    _hasTested = true;
    return _activeHost;
  }
}
