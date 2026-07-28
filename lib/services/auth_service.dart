import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost/minesec_api/api/auth.php';

  static const String _keyToken    = 'auth_token';
  static const String _keyUserId   = 'user_id';
  static const String _keyFullName = 'full_name';
  static const String _keyRole     = 'user_role';
  static const String _keySchoolId = 'school_id';
  static const String _keyRegion   = 'region';
  static const String _keyDivision = 'division';

  // ── Check if matricule exists in DB ───────────────────────────
  static Future<Map<String, dynamic>> checkMatricule(String matricule) async {
    final res = await http.post(
      Uri.parse('$_baseUrl?action=check_matricule'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'matricule': matricule}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw data['message'] ?? 'Unknown error';
    return data['data'] as Map<String, dynamic>;
  }

  // ── Activate account (first time) ─────────────────────────────
  static Future<UserModel> activateAccount({
    required String matricule,
    required String password,
    required String securityCode,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl?action=activate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'matricule':     matricule,
        'password':      password,
        'security_code': securityCode,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) throw data['message'] ?? 'Activation failed';

    final payload = data['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(payload, payload['token'] as String);
    await _saveSession(user);
    return user;
  }

  // ── Login (returning users) ────────────────────────────────────
  static Future<UserModel> login({
    required String matricule,
    required String password,
    required String securityCode,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl?action=matricule_login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'matricule':     matricule,
        'password':      password,
        'security_code': securityCode,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw data['message'] ?? 'Login failed';

    final payload = data['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(payload, payload['token'] as String);
    await _saveSession(user);
    return user;
  }

  // ── Save session to local storage ────────────────────────────
  static Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken,    user.token);
    await prefs.setInt   (_keyUserId,   user.id);
    await prefs.setString(_keyFullName, user.fullName);
    await prefs.setString(_keyRole,     user.role);
    if (user.schoolId != null) await prefs.setInt(_keySchoolId, user.schoolId!);
    if (user.region   != null) await prefs.setString(_keyRegion,   user.region!);
    if (user.division != null) await prefs.setString(_keyDivision, user.division!);
  }

  // ── Load saved session ────────────────────────────────────────
  static Future<UserModel?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token  = prefs.getString(_keyToken);
    final userId = prefs.getInt(_keyUserId);
    final name   = prefs.getString(_keyFullName);
    final role   = prefs.getString(_keyRole);
    if (token == null || userId == null || name == null || role == null) return null;
    return UserModel(
      id:       userId,
      fullName: name,
      role:     role,
      token:    token,
      schoolId: prefs.getInt(_keySchoolId),
      region:   prefs.getString(_keyRegion),
      division: prefs.getString(_keyDivision),
    );
  }

  // ── Sign out ──────────────────────────────────────────────────
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
