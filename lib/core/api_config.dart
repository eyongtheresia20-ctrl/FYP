import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static const String _port = '8080';
  static String _activeHost = '127.0.0.1:8080';
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

  /// Automatically tests and finds the working host IP for Android
  static Future<String> getWorkingHost() async {
    if (kIsWeb) return 'localhost:$_port';
    if (_hasTested) return _activeHost;

    final candidates = [
      '127.0.0.1:$_port',
      'localhost:$_port',
      '192.168.1.148:$_port',
      '10.0.2.2:$_port',
    ];

    for (final candidate in candidates) {
      try {
        final res = await http
            .get(Uri.parse('http://$candidate/minesec_api/api/admin.php?action=get_all_schools'))
            .timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
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
