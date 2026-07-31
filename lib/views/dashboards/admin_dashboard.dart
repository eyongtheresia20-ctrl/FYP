import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_sidebar.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;
  final bool isDarkMode;
  final bool isEn;

  const AdminDashboard({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.isEn,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late UserModel _currentUser;
  late bool _isDarkMode;
  late bool _isEn;

  bool _isLoading = true;
  Map<String, dynamic> _totals = {};
  int _currentNavIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Color get _green  => const Color(0xFF006A4E);
  Color get _bg     => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _card   => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get _text   => _isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _sub    => _isDarkMode ? Colors.white60 : const Color(0xFF64748B);
  Color get _border => _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _isDarkMode = widget.isDarkMode;
    _isEn = widget.isEn;
    _fetchAdminTotals();
  }

  Future<void> _fetchAdminTotals() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse('http://localhost:8080/minesec_api/api/dashboard.php?action=admin_totals'),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        setState(() {
          _totals = data['data'] ?? {};
          _isLoading = false;
        });
      } else {
        _useFallbackTotals();
      }
    } catch (_) {
      _useFallbackTotals();
    }
  }

  void _useFallbackTotals() {
    setState(() {
      _isLoading = false;
      _totals = {
        'total_schools': 240,
        'total_users': 45000,
        'total_students': 42000,
        'total_teachers': 2800,
        'total_assessed': 36500,
        'total_regions': 10,
        'total_divisions': 58,
      };
    });
  }

  void _showAdminProfileDialog() async {
    final passCtrl    = TextEditingController(text: 'password123');
    final secCodeCtrl = TextEditingController(text: '1234');
    bool obscurePass  = true;
    bool obscureSec   = true;
    bool saving       = false;

    try {
      final res = await http.get(
        Uri.parse('http://localhost:8080/minesec_api/api/auth.php?action=get_profile&user_id=${_currentUser.id}'),
      );
      final pData = jsonDecode(res.body);
      if (pData['success'] == true && pData['data'] != null) {
        final profile = pData['data'];
        if (profile['password'] != null) passCtrl.text = profile['password'];
        if (profile['security_code'] != null) secCodeCtrl.text = profile['security_code'];
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final initials = _currentUser.fullName.trim().split(' ')
              .take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.90),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: _border)),
            ),
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_green, const Color(0xFF009966)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              initials.isEmpty ? 'A' : initials,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser.fullName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  _isEn ? 'MINESEC Administrator' : 'Administrateur MINESEC',
                                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  _profileInfoRow(Icons.person_outline_rounded, _isEn ? 'Full Name' : 'Nom Complet', _currentUser.fullName),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.admin_panel_settings_outlined, _isEn ? 'Matricule' : 'Matricule', _currentUser.matNumber ?? 'MINESEC001'),
                  const SizedBox(height: 14),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isEn ? 'Modify Present Password & Security Code' : 'Modifier Mot de Passe & Code de Sécurité',
                      style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 1. PRESENT PASSWORD INPUT (FIRST)
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    decoration: InputDecoration(
                      labelText: _isEn ? 'Present Password' : 'Mot de Passe Présent',
                      labelStyle: TextStyle(color: _sub, fontSize: 12),
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: _green, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, color: _sub, size: 20),
                        onPressed: () => setModalState(() => obscurePass = !obscurePass),
                      ),
                      filled: true,
                      fillColor: _bg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. PRESENT SECURITY CODE INPUT (SECOND)
                  TextField(
                    controller: secCodeCtrl,
                    obscureText: obscureSec,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      labelText: _isEn ? 'Present Security Code (e.g. 1234 or SEC#2026)' : 'Code de Sécurité Présent (ex: 1234 ou SEC#2026)',
                      labelStyle: TextStyle(color: _sub, fontSize: 12),
                      prefixIcon: Icon(Icons.security_rounded, color: _green, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureSec ? Icons.visibility_off : Icons.visibility, color: _sub, size: 20),
                        onPressed: () => setModalState(() => obscureSec = !obscureSec),
                      ),
                      filled: true,
                      fillColor: _bg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: saving ? null : () async {
                        final newPass = passCtrl.text.trim();
                        final newSec  = secCodeCtrl.text.trim();

                        setModalState(() => saving = true);

                        try {
                          final resp = await http.post(
                            Uri.parse('http://localhost:8080/minesec_api/api/auth.php?action=update_profile'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'user_id': _currentUser.id,
                              if (newPass.isNotEmpty) 'password': newPass,
                              if (newSec.isNotEmpty) 'security_code': newSec,
                            }),
                          );

                          if (mounted) {
                            Navigator.pop(ctx);
                          } else {
                            setModalState(() => saving = false);
                          }
                        } catch (e) {
                          setModalState(() => saving = false);
                        }
                      },
                      icon: saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(
                        saving ? (_isEn ? 'Saving...' : 'Enregistrement...') : (_isEn ? 'Save Changes' : 'Enregistrer les Modifications'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(_isEn ? 'Cancel' : 'Annuler', style: TextStyle(color: _sub)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSchools  = _totals['total_schools'] ?? 240;
    final totalUsers    = _totals['total_users'] ?? 45000;
    final totalStudents = _totals['total_students'] ?? 42000;
    final totalAssessed = _totals['total_assessed'] ?? 36500;

    final isWide = MediaQuery.of(context).size.width >= 800;

    final sidebarWidget = AppSidebar(
      user: _currentUser,
      isDarkMode: _isDarkMode,
      isEn: _isEn,
      selectedIndex: _currentNavIndex,
      onItemSelected: (idx) => setState(() => _currentNavIndex = idx),
      onOpenProfile: _showAdminProfileDialog,
      onToggleTheme: () => setState(() => _isDarkMode = !_isDarkMode),
      onToggleLanguage: () => setState(() => _isEn = !_isEn),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: isWide ? null : sidebarWidget,
      body: Row(
        children: [
          if (isWide) sidebarWidget,
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF0B132B),
                    border: Border(bottom: BorderSide(color: _isDarkMode ? const Color(0x22FFFFFF) : const Color(0xFF1E293B))),
                  ),
                  child: Row(
                    children: [
                      if (!isWide)
                        IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                      Text(
                        _isEn ? 'MINESEC Central Administration Dashboard' : 'Tableau de Bord Administration Centrale MINESEC',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => setState(() => _isEn = !_isEn),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
                          child: Text(_isEn ? 'EN 🇬🇧' : 'FR 🇫🇷', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(_isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: const Color(0xFFFCD116), size: 20),
                        onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
                        onPressed: _showAdminProfileDialog,
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Admin Banner Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_green, const Color(0xFF009966)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: _green.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_currentUser.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(_isEn ? 'MINESEC Central Administrator' : 'Administrateur Central MINESEC', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _scopeBadge(Icons.admin_panel_settings_rounded, 'Matricule: ${_currentUser.matNumber ?? "MINESEC001"}'),
                                  _scopeBadge(Icons.map_rounded, _isEn ? 'National Coverage' : 'Couverture Nationale'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stats Grid
                        Row(
                          children: [
                            Expanded(child: _statCard(_isEn ? 'Total Schools' : 'Établissements', '$totalSchools', Icons.school_rounded, const Color(0xFF3B82F6))),
                            const SizedBox(width: 10),
                            Expanded(child: _statCard(_isEn ? 'Total System Users' : 'Utilisateurs', '$totalUsers', Icons.badge_rounded, const Color(0xFF8B5CF6))),
                            const SizedBox(width: 10),
                            Expanded(child: _statCard(_isEn ? 'Total Students' : 'Total Élèves', '$totalStudents', Icons.groups_rounded, const Color(0xFF10B981))),
                            const SizedBox(width: 10),
                            Expanded(child: _statCard(_isEn ? 'Assessed Students' : 'Élèves Évalués', '$totalAssessed', Icons.task_alt_rounded, const Color(0xFFF59E0B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _scopeBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
